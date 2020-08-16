#!/usr/bin/env python3

import dateutil.parser
import json
import os
import re
import requests
import subprocess
import time
import traceback
import sys

import docker

from aliyunsdkcore.client import AcsClient
from aliyunsdkcr.request.v20160607 import GetRepoTagsRequest


def repolize(repo):
    repos = repo.split('/')
    if len(repos) == 1:
        repos = ['docker.io', 'library', repos[0]]
    if len(repos) == 2:
        if '.' not in repos[0]:
            repos = ['docker.io', repos[0], repos[1]]
    return repos

def searchTags(url, key):
    r = requests.get(url)
    if r.status_code == 200:
        return r.json().get(key, [])

def run(cmd):
    return subprocess.check_output(cmd, shell=True)

def get_acr_tags(ns,repo):
    acr_tags = []
    req.set_RepoNamespace(ns)
    req.set_RepoName(repo)
    try:
        res = apiClient.do_action_with_exception(req).decode()
    except:
        return acr_tags

    data = json.loads(res)

    print(data)
    for i in data['data']['tags']:
        acr_tags.append(i['tag'])

    return acr_tags

def get_push_tags(atags,ntags):
    return [item for item in ntags if item not in atags]

def get_expect_tags(tlist, num):
    ltemp = []
    tlist.sort(key=lambda tlist: tlist[0], reverse=True)
    for x in tlist:
        if x[1] not in ltemp:
            ltemp.append(x[1])
    return ltemp[:num]

def get_repo_tags(repos, tag_regexp, num):
    result = []
    temp_result = []
    if repos[0] == 'docker.io':
        url = 'https://registry.hub.docker.com/v2/repositories/%s/%s/tags/?page_size=1000' % (repos[1], repos[2])
        tags = searchTags(url, 'results')
        for image in tags:
            timeUpload = time.mktime(dateutil.parser.parse(image['last_updated']).timetuple()) * 1000
            tag = image['name']
            if len(tags) > 0:
                if re.search(tag_regexp,tag):
                    temp_result.append((timeUpload,tag))
    elif repos[0] == 'quay.io':
        url = 'https://quay.io/api/v1/repository/%s/%s/tag/' % (repos[1], repos[2])
        tags = searchTags(url, 'tags')
        for image in tags:
            timeUpload = float(image['start_ts']) * 1000
            tag = image['name']
            if len(tags) > 0:
                if re.search(tag_regexp,tag):
                    temp_result.append((timeUpload,tag))
    else:
        url = 'https://%s/v2/%s/%s/tags/list' % (repos[0], repos[1], repos[2]) if len(repos) == 3 else 'https://%s/v2/%s/tags/list' % (repos[0], repos[1])
        manifest = searchTags(url, 'manifest')
        for key in manifest:
            image = manifest[key]
            timeUpload = float(image['timeUploadedMs'])
            tags = image['tag']

            if len(tags) > 0:
                for tag in tags:
                    if re.search(tag_regexp,tag):
                        temp_result.append((timeUpload,tag))

    result = get_expect_tags(temp_result, num)
    return result

def sync_repo(client, rrepos, lrepos, tags):
    for tag in tags:
        try:
            image = client.images.pull(rrepos, tag=tag)
            image.tag(lrepos, tag)
            client.images.push(lrepos, tag=tag, auth_config=g_docker_auth)
        except Exception:
            traceback.print_exc()

filename = 'sync_to_acr.list'
sync_nums = 10

envs = os.environ

apiClient = AcsClient(envs['ACR_KEYID'], envs['ACR_SECRET'])
req = GetRepoTagsRequest.GetRepoTagsRequest()
req.set_protocol_type('https')

g_docker_auth = {'username': envs['ACR_DOCKER_USERNAME'], 'password': envs['ACR_DOCKER_PASSWORD']}

client = docker.from_env()

if not os.path.exists(filename):
    sys.exit(1)
lines = [line.strip() for line in open(filename)]

for line in lines:
    if line.startswith('#'):
        continue
    if line == '':
        continue
    try:
        repos = line.split(":")
        remote_repos = repolize(repos[0])
        acr_repos = repolize(repos[1])
        acr_repos.append('_'.join(remote_repos))
        tag_regexp = repos[2]
        remote_tags = get_repo_tags(remote_repos, tag_regexp, sync_nums)
        acr_region = acr_repos[0].split('.')[1]
        apiClient.set_region_id(acr_region)
        acr_tags = get_acr_tags(acr_repos[1], acr_repos[2])
        sync_tags = get_push_tags(acr_tags, remote_tags)
        print(remote_tags, acr_tags, sync_tags)
        # sync_repo(client, '/'.join(remote_repos), '/'.join(acr_repos), sync_tags)
    except Exception:
        traceback.print_exc()
