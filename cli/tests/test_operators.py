#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

import os
import re

import pytest

from cloudsack import operators


class TestOperator(object):

    @pytest.fixture(autouse=True)
    def operator(self):
        operators.Operator.dir_name = 'testing_testing'
        operator = operators.Operator('test', {'base_fqin': 'base_fqin'})
        yield operator

    def test_get_base_template_name(self, operator):
        operator.base_template_name = 'test'
        assert 'test' == operator.get_base_template_name()
        del operator.base_template_name
        assert 'testing' == operator.get_base_template_name()

    def test_get_base_template_ext(self, operator):
        assert 'yaml' == operator.get_base_template_ext()
        operator.base_template_ext = 'j2'
        assert 'j2' == operator.get_base_template_ext()

    def test_get_template_name(self, operator):
        assert 'testing.yaml.j2' == operator.get_template_name()

    def test_get_template_retrieve_name(self, operator):
        assert 'test/testing.yaml.j2' == operator.get_template_retrieve_name()

    def test_unique_dir_name(self, operator):
        pattern = (
            '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
        dir_name, uuid = operator.get_unique_dir_name().split('_')
        assert 'test' == dir_name
        assert re.match(pattern, uuid) is not None

    def test_get_arena(self, operator):
        pattern = (
            '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
        arena = operator.get_arena()
        assert operator.work_area == os.path.dirname(arena)
        dir_name, uuid = os.path.basename(arena).split('_')
        assert 'test' == dir_name
        assert re.match(pattern, uuid) is not None

    def test_render(self, operator, mocker, monkeypatch):
        arena = operator.get_arena()
        mock = mocker.MagicMock()
        monkeypatch.setattr('cloudsack.utils.Renderer.write', mock)
        operator.render(arena)
        mock.assert_called_with(
            os.path.join(arena, operator.get_operation_file_name())
        )


class TestImageBuilder(object):

    @pytest.fixture(autouse=True)
    def image_builder(self):
        image_builder = operators.ImageBuilder(
            'core',
            'localhost:5000/test/version_core:v1',
            {'base_fqin': 'base_fqin'},
        )
        yield image_builder

    def test_get_template_retrieve_name(self, image_builder):
        expected = 'core/build_image/Dockerfile.j2'
        result = image_builder.get_template_retrieve_name()
        assert result == expected

    def test_build(self, image_builder, mocker, monkeypatch):
        render_mock = mocker.MagicMock()
        image_builder.render = render_mock
        build_mock = mocker.MagicMock()
        monkeypatch.setattr('cloudsack.dockerclient.Docker.build_image',
                            build_mock)
        image_builder.build()
        render_mock.assert_called()
        build_mock.assert_called_with(
            render_mock.call_args[0][0],
            'localhost:5000/test/version_core:v1',
        )
