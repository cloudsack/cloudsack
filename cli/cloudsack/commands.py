#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function, unicode_literals

from cloudsack import const
from cloudsack.director import Director
from cloudsack.components import component_factory


class Build(object):

    def __init__(self, args):
        self.args = args

    def __prepare(self):
        """Checks input and prepare appropriate input."""
        if not self.args.image_names:
            self.args.image_names = const.COMPONENTS

    def __build(self):
        for image_name in self.args.image_names:
            component_class = component_factory(image_name)
            component = component_class(self.args.config)
            director = Director(component)
            director.build()
            print('Successfully built: {}'.format(image_name))

    def perform(self):
        self.__prepare()
        self.__build()
