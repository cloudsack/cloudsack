#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals, print_function
from future.utils import with_metaclass

import os
import uuid

from cloudsack import utils
from cloudsack import const
from cloudsack.kubeclient import Kube
from cloudsack.dockerclient import Docker


class Operator(with_metaclass(utils.Directory, object)):

    dir_name = None
    template_prefix = 'j2'

    def __init__(self, component_name, context):
        self.component_name = component_name
        self.context = context

    def get_base_template_name(self):
        if hasattr(self, 'base_template_name'):
            return self.base_template_name
        else:
            return self.dir_name.split('_')[0]

    def get_base_template_ext(self):
        if hasattr(self, 'base_template_ext'):
            return self.base_template_ext
        else:
            return 'yaml'

    def get_template_name(self):
        _ = [
            self.get_base_template_name(),
            self.get_base_template_ext(),
            self.template_prefix,
        ]
        return os.path.extsep.join(
            [str(i) for i in _ if i])

    def get_operation_file_name(self):
        _ = [
            self.get_base_template_name(),
            self.get_base_template_ext(),
        ]
        return os.path.extsep.join(
            [str(i) for i in _ if i])

    def get_template_retrieve_name(self):
        return os.path.join(self.component_name,
                            self.get_template_name())

    def get_unique_dir_name(self):
        return '_'.join([self.component_name, str(uuid.uuid4())])

    def get_arena(self):
        return os.path.join(self.work_area, self.get_unique_dir_name())

    def render(self, arena):
        renderer = utils.Renderer(
            self.get_template_retrieve_name(), self.context)
        operation_file_name = os.path.join(
            arena, self.get_operation_file_name())
        renderer.write(operation_file_name)


class ImageBuilder(Operator):

    dir_name = 'image_building'
    base_template_name = 'Dockerfile'
    base_template_ext = None

    def __init__(self, component_name, fqin, context):
        self.component_name = component_name
        self.fqin = fqin
        self.context = context

    def get_template_retrieve_name(self):
        return os.path.join(
            self.component_name,
            'build_image',
            self.get_template_name()
        )

    def build(self):
        source = os.path.join(
            const.TEMPLATE_PATH, self.component_name, 'build_image')

        with utils.make(self.get_arena(), src=source) as arena:
            self.render(arena)
            # TODO: Handler exception
            # TODO: Move `insecure=True` to configuration
            client = Docker(insecure=True)
            client.build_image(
                arena,
                self.fqin,
            )


class ServiceCreator(Operator):

    dir_name = 'service_creation'
    base_template_name = 'service'

    def build(self):
        with utils.make(self.get_arena()) as arena:
            self.render(arena)
            file_name = os.path.join(arena, self.get_operation_file_name())
            kube = Kube()
            kube.create_service(file_name)


class JobCreator(Operator):

    dir_name = 'endpoint_creation'
    base_template_name = 'create_endpoint_job'

    def create(self):
        with utils.make(self.get_arena()) as arena:
            self.render(arena)
            file_name = os.path.join(arena, self.get_operation_file_name())
            kube = Kube()
            kube.create_job(file_name)
