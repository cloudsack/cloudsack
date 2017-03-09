#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

from builtins import str
from future.utils import with_metaclass

import re
import os
import uuid
import shutil
import argparse
import tempfile

import pytest
import jinja2

from cloudsack import utils, const


def test_directory():

    class Temp(with_metaclass(utils.Directory, object)):
        dir_name = 'abc'

    Temp()
    path = os.path.join(const.WORK_DIR, 'abc')
    assert os.path.exists(path)
    shutil.rmtree(path)


def test_get_fqin():
    registry = 'localhost:5000'
    username = 'test'
    os_version = 'mitaka'
    name = 'base'
    tag = 'v1'
    expected = '{}/{}/{}_{}:{}'.format(registry, username,
                                       os_version, name, tag,)
    result = utils.get_fqin(registry, username,
                            os_version, tag, name,)
    assert result == expected


def test_get_name_from_fqin():
    full_image_name = 'reg/proj/test_base:v1'
    expected = 'base'
    result = utils.get_name_from_fqin(full_image_name)
    assert result == expected


def test_make():
    name = os.path.join(tempfile.gettempdir(), str(uuid.uuid4()))
    context = utils.make(name)
    actual = next(context.gen)
    assert name == actual
    assert os.path.exists(name)
    try:
        next(context.gen)
    except StopIteration:
        pass
    assert not os.path.exists(name)


def test_make_remove_existing():
    dir_name = tempfile.mkdtemp()
    file_name = tempfile.mkstemp(dir=dir_name)[1]
    context = utils.make(dir_name)
    next(context.gen)
    assert os.path.exists(dir_name)
    assert not os.path.exists(file_name)
    try:
        next(context.gen)
    except StopIteration:
        pass


def test_make_copy_dir():
    name = os.path.join(tempfile.gettempdir(), str(uuid.uuid4()))
    src = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'copyme')
    context = utils.make(name, src=src)
    actual = next(context.gen)
    assert name == actual
    assert os.path.exists(os.path.join(name, 'temp.sh'))
    assert os.path.exists(os.path.join(name, 'temp.j2'))
    try:
        next(context.gen)
    except StopIteration:
        pass
    assert not os.path.exists(name)


def test_make_unique():
    name = 'abc'
    pattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
    res = utils.make_unique(name)
    assert re.search(pattern, res) is not None


class TestRenderer(object):

    @pytest.fixture(autouse=True)
    def setup(self):
        context = {
            'base_fqin': 'localhost:5000/test/version_base:v1'
        }
        renderer = utils.Renderer('core/build_image/Dockerfile.j2', context)
        yield {
            'context': context,
            'renderer': renderer,
        }

    def test_render(self, setup):
        context = setup['context']
        renderer = setup['renderer']
        template_name = 'cloudsack/templates/core/build_image/Dockerfile.j2'
        with open(template_name) as stream:
            template = stream.read()
        expected = jinja2.Template(template).render(**context)
        result = renderer.render()
        assert result == expected

    def test_write(self, setup):
        renderer = setup['renderer']
        temp_file = tempfile.mkstemp()[1]
        expected = renderer.render()
        renderer.write(temp_file)
        with open(temp_file) as stream:
            result = stream.read()
        assert result == expected


class TestYamlFile(object):

    @pytest.fixture(autouse=True)
    def yaml_file_name(self):
        temp_dir = tempfile.mkdtemp()
        temp_file_name = os.path.join(temp_dir, 'test.yaml')
        with open(temp_file_name, 'w') as yaml:
            yaml.write('a: 1\nb: 2')
        yield temp_file_name
        shutil.rmtree(temp_dir)

    def test_yaml_file_return(self, yaml_file_name):
        expected = {'a': 1, 'b': 2}
        result = utils.yaml_file(yaml_file_name)
        assert result == expected

    def test_yaml_invalid_file_path(self, yaml_file_name):
        invalid_yaml_file_name = yaml_file_name + 'a'
        with pytest.raises(IOError):
            utils.yaml_file(invalid_yaml_file_name)

    def test_yaml_invalid_file_content(self, yaml_file_name):
        with open(yaml_file_name, 'a') as yaml:
            yaml.write('\n:a')
        with pytest.raises(argparse.ArgumentTypeError):
            utils.yaml_file(yaml_file_name)
