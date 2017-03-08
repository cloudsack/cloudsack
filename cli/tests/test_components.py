#!/usr/bin/python
# -*- coding: utf-8 -*-

from builtins import object

from cloudsack import utils
from cloudsack.components import Base


class TestBase(object):

    def test_fqin(self):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        component.name = 'core'
        expected = utils.get_fqin(
            'localhost:5000',
            'test',
            'version',
            'v1',
            'core',
        )
        result = component.fqin
        assert result == expected

    def test_base_fqin(self):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        component.name = 'core'
        expected = utils.get_fqin(
            'localhost:5000',
            'test',
            'version',
            'v1',
            'test',
        )
        result = component.base_fqin
        assert result == expected

    def test_build_context(self):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        expected = {'base_fqin': component.base_fqin}
        result = component.build_context
        assert result == expected

    def test_build(self, monkeypatch, mocker):
        config = {
            'docker': {
                'registry': 'localhost:5000',
                'username': 'test',
                'os_version': 'version',
                'tag': 'v1',
                'base_image': 'test',
            }
        }
        component = Base(config)
        component.name = 'test'
        obj_mock = mocker.MagicMock()
        class_mock = mocker.MagicMock(return_value=obj_mock)
        monkeypatch.setattr('cloudsack.components.operators.ImageBuilder',
                            class_mock)
        component.build()
        class_mock.assert_called_with(
            component.name,
            component.fqin,
            component.build_context,
        )
        obj_mock.build.assert_called()
