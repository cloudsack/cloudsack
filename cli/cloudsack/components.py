#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
from six import string_types
from future.utils import iteritems

from cloudsack import utils
from cloudsack import operators


class Base(object):

    def __init__(self, configs):
        self.configs = configs

    @property
    def fqin(self):
        return utils.get_fqin(
            self.configs['docker']['registry'],
            self.configs['docker']['username'],
            self.configs['docker']['os_version'],
            self.configs['docker']['tag'],
            self.name,
        )

    @property
    def base_fqin(self):
        return utils.get_fqin(
            self.configs['docker']['registry'],
            self.configs['docker']['username'],
            self.configs['docker']['os_version'],
            self.configs['docker']['tag'],
            self.configs['docker']['base_image'],
        )

    @property
    def build_context(self):
        return {
            'base_fqin': self.base_fqin,
        }

    @property
    def build_service_context(self):
        service_config = self.config['services'][self.name]
        service_config.update({
            'namespace': self.config['namespace'],
            'unit_name': self.name,
        })
        return service_config

    def global_configs(self):
        """All top level configs."""
        # TODO: Make dict python2 and python3 safe
        return {key: value
                for key, value in iteritems(self.configs)
                if isinstance(value, string_types)}

    @property
    def component_configs(self):
        """All config of component present under service section."""
        # TODO: Make dict python2 and python3 safe
        return self.configs['services'][self.name]

    @property
    def keystone_configs(self):
        return self.configs['services']['keystone']

    def build(self):
        image_builder = operators.ImageBuilder(
            self.name,
            self.fqin,
            self.build_context,
        )
        image_builder.build()


class Core(Base):

    name = 'core'


class MySql(Base):

    name = 'mysql'


class RabbitMQ(Base):

    name = 'rabbitmq'


class MemcacheD(Base):

    name = 'memcached'


class Keystone(Base):

    name = 'keystone'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
        }

    def launch(self):
        endpoint_creator = operators.EndPointCreator(
            self.name,
            self.end_point_creator_context,
        )
        endpoint_creator.create()


class Glance(Base):

    name = 'glance'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
            'keystone': self.keystone_configs,
        }


class Nova(Base):

    name = 'nova'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
            'keystone': self.keystone_configs,
        }


class Neutron(Base):

    name = 'neutron'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
            'keystone': self.keystone_configs,
        }


class Horizon(Base):

    name = 'horizon'


class Cinder(Base):

    name = 'cinder'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
            'keystone': self.keystone_configs,
        }


class Heat(Base):

    name = 'heat'

    @property
    def create_job_context(self):
        return {
            'name': self.name,
            'base_fqin': self.base_fqin,
            'globals': self.global_configs,
            'component': self.component_configs,
            'keystone': self.keystone_configs,
        }


def component_factory(name):
    components = {
        'core': Core,
        'mysql': MySql,
        'rabbitmq': RabbitMQ,
        'memcached': MemcacheD,
        'keystone': Keystone,
        'glance': Glance,
        'nova': Nova,
        'neutron': Neutron,
        'horizon': Horizon,
        'cinder': Cinder,
        'heat': Heat,
    }
    return components[name]
