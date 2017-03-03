#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals, print_function

import docker


class Docker(object):

    def __init__(self, insecure=False):
        self.client = None
        self.insecure = insecure

    def __connect(self):
        self.client = docker.from_env()

    def build_image(self, path, image_name):
        self.__connect()
        print('Build path: {}'.format(path))
        print('Starting to build: {}'.format(image_name))
        # import pytest; pytest.set_trace()
        self.client.images.build(
            path=path,
            tag=image_name,
            timeout=600,
            rm=True,
            forcerm=True,
        )
        for line in self.client.images.push(image_name,
                                            stream=True,
                                            insecure_registry=self.insecure):
            print('.', end='')
