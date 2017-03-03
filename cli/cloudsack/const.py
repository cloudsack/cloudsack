#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os


BASE_PATH = os.path.abspath(os.path.dirname(__file__))

TEMPLATE_PATH = os.path.join(BASE_PATH, 'templates')

WORK_DIR = '/tmp/csack'

COMPONENTS = [
    'core',
    'mysql',
    'rabbitmq',
    'memcached',
    'keystone',
    'glance',
    'nova',
    'neutron',
    'horizon',
    'cinder',
    'heat',
]

try:
    os.mkdir(WORK_DIR)
except OSError:
    pass
