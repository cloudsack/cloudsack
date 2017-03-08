#!/usr/bin/python
# -*- coding: utf-8 -*-

from builtins import object

import yaml
import pykube


class Kube(object):

    def __init__(self):
        # TODO: Dynamic config locaiton
        self.api = pykube.HTTPClient(
            pykube.KubeConfig.from_file('/root/.kube/config'))

    def create_job(self, file_name):
        with open(file_name) as stream:
            content = yaml.load(stream.read())
        pykube.Job(self.api, content).create()
