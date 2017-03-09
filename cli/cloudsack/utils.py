#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
from builtins import str

import os
import re
import uuid
import shutil
import argparse
from contextlib import contextmanager

import yaml
from jinja2 import Environment, PackageLoader

from const import WORK_DIR


def get_fqin(registry, username, os_version, tag, name):
    """Returns fully qualified image name."""
    return '{}/{}/{}_{}:{}'.format(
        registry,
        username,
        os_version,
        name,
        tag,
    )


def get_name_from_fqin(full_image_name):
    """Extracts image name from fully qualified image name."""
    match = re.match('^\w+/\w+/\w+_(?P<image_name>[\w-]+):\w+$',
                     full_image_name)
    # TODO: Raise exception about invalid full image name
    return match.groupdict().get('image_name')


@contextmanager
def make(name, src=None):
    """Context to create and remove directory.

    If optional `src` path is given, it recursively copies `src` into
    newly created directory.

    """
    if os.path.exists(name):
        shutil.rmtree(name)
    if src:
        shutil.copytree(src, name)
    else:
        os.mkdir(name)
    yield name
    shutil.rmtree(name)


def make_unique(name):
    """Adds uuid to name to make it unique."""
    return name + str(uuid.uuid4())


def yaml_file(name):
    """A custom `argparse` type for yaml file."""
    file_name = os.path.abspath(os.path.expanduser(name))
    if not os.path.exists(file_name):
        error_message = 'File not found {}'.format(file_name)
        raise IOError(error_message)
    with open(file_name) as stream:
        try:
            value = yaml.safe_load(stream)
        except yaml.YAMLError:
            error_message = 'Error parsing yaml file.'
            raise argparse.ArgumentTypeError(error_message)
    return value


class Directory(type):

    """A metaclass which makes sure that working path exists."""

    def get_path(cls):
        return os.path.join(WORK_DIR, cls.dir_name)

    def __call__(cls, *args, **kwargs):
        cls.work_area = cls.get_path()
        if not os.path.exists(cls.work_area):
            os.mkdir(cls.work_area)
        return super(Directory, cls).__call__(*args, **kwargs)


class Renderer(object):

    env = Environment(loader=PackageLoader(
        'cloudsack',
        'templates'
    ))

    def __init__(self, template_name, context):
        self.template_name = template_name
        self.context = context

    def __get_template(self):
        return self.env.get_template(self.template_name)

    def render(self):
        template = self.__get_template()
        return template.render(**self.context)

    def write(self, file_name):
        with open(file_name, 'w') as stream:
            stream.write(self.render())
