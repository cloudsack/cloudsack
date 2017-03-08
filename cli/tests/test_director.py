#!/usr/bin/python
# -*- coding: utf-8 -*-


from cloudsack.components import Base
from cloudsack.director import Director


class TestDirector(object):

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
        monkeypatch.setattr('cloudsack.director.operators.ImageBuilder',
                            class_mock)
        director = Director(component)
        director.build()
        class_mock.assert_called_with(
            component.name,
            component.fqin,
            component.build_context,
        )
        obj_mock.build.assert_called()
