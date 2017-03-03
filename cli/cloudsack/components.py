#!/usr/bin/python
# -*- coding: utf-8 -*-


from cloudsack import utils


class Base(object):

    def __init__(self, config):
        self.config = config

    @property
    def fqin(self):
        return utils.get_fqin(
            self.config['docker']['registry'],
            self.config['docker']['username'],
            self.config['docker']['os_version'],
            self.config['docker']['tag'],
            self.name,
        )

    @property
    def build_context(self):
        base_fqin = utils.get_fqin(
            self.config['docker']['registry'],
            self.config['docker']['username'],
            self.config['docker']['os_version'],
            self.config['docker']['tag'],
            self.config['docker']['base_image'],
        )
        return {
            'base_fqin': base_fqin,
        }


class Core(Base):

    name = 'core'


class MySql(Base):

    name = 'mysql'
    launch_operations = [
        'create_service', 'create_deployment'
    ]


class RabbitMQ(Base):

    name = 'rabbitmq'


class MemcacheD(Base):

    name = 'memcached'


class Keystone(Base):

    name = 'keystone'


class Glance(Base):

    name = 'glance'


class Nova(Base):

    name = 'nova'


class Neutron(Base):

    name = 'neutron'


class Horizon(Base):

    name = 'horizon'


class Cinder(Base):

    name = 'cinder'


class Heat(Base):

    name = 'heat'


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
