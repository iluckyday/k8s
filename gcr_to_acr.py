#!/usr/bin/env python3

import json
import os
import re
import subprocess

from distutils.version import LooseVersion

from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkcore.client import AcsClient
from aliyunsdkcr.request.v20160607 import GetRepoTagsRequest


def run(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    d = p.stdout.read()
    p.stdout.close()
    ret = p.wait()
    if ret != 0:
        raise Exception('%s execute error: %s' %(cmd, d))
    else:
        return d

def get_acr_tags(ns,repo):
    req.set_RepoNamespace(ns)
    req.set_RepoName(repo)
    try:
        res = apiClient.do_action_with_exception(req).decode()
    except ServerException as e:
        raise Exception(e)
    except ClientException as e:
        raise Exception(e)

    data = json.loads(res)
    acr_tags = []

    for i in data['data']['tags']:
        acr_tags.append(i)

    return acr_tags

def get_nonacr_tags(nurl,ns,repo,tagexp):
    url = 'https://' + nurl + '/v2/' + ns + '/' + repo + '/tags/list'
    cmd = 'curl -skL ' + url

    ds = json.loads(run(cmd).decode())

    gcr_tags = []
    for i in ds['tags']:
        if re.search(tagexp,i):
            gcr_tags.append(i)

    lv = []
    lv = [LooseVersion(v) for v in gcr_tags]
    lv.sort(reverse = True)

    return [lv[0].vstring]

def acr_login(url):
    cmd = 'docker login -u ' + envs['ACR_DOCKER_USERNAME'] + ' -p ' + envs['ACR_DOCKER_PASSWORD'] + url
    run(cmd)

def acr_logout(url):
    cmd = 'docker logout ' + url
    run(cmd)

def push_image(aurl,ans,arepo,nurl,nns,nrepo,tag):
    cmd = 'docker pull ' + nurl + '/' + nns + '/' + nrepo + ':' + tag
    cmd += '\ndocker tag ' + nurl + '/' + nns + '/' + nrepo + ':' + tag + ' ' + aurl + '/' + ans + '/' + arepo + ':' + tag
    cmd += '\ndocker push ' + aurl + '/' + ans + '/' + arepo + ':' + tag
    print(run(cmd))

def get_push_tags(atags,ntags):
    return [item for item in ntags if item not in atags]

fo = open('gcr_to_acr.list', 'r')
fdata = fo.read()
fo.close()

envs = os.environ

apiClient = AcsClient(envs['ACR_KEYID'], envs['ACR_SECRET'])
req = GetRepoTagsRequest.GetRepoTagsRequest()
req.set_protocol_type('https')

all_urls = []
for line in fdata.splitlines():
    if line:
        aurl = line.split(':')[1].split('/')[0]
        if aurl not in all_urls:
            all_urls.append(aurl)

for u in all_urls:
    if u:
        print(u)
        acr_login(u)

for line in fdata.splitlines():
    if line:
        nurl = line.split(':')[0].split('/')[0]
        aurl = line.split(':')[1].split('/')[0]
        nns = line.split(':')[0].split('/')[1]
        ans = line.split(':')[1].split('/')[1]
        nrepo = line.split(':')[0].split('/')[2]
        arepo = line.split(':')[1].split('/')[2]
        acr_region = aurl.split('.')[1]
        tagexp = line.split(':')[2]
        apiClient.set_region_id(acr_region)
        ntags = get_nonacr_tags(nurl, nns, nrepo, tagexp)
        atags = get_acr_tags(ans, arepo)
        ptags = get_push_tags(atags, ntags)
        if ptags:
            for t in ptags:
                push_image(aurl,ans,arepo,nurl,nns,nrepo,t)

print(run('docker image ls'))

for u in all_urls:
    acr_logout(u)
