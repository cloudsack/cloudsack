#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function, unicode_literals

from cloudsack import const
from cloudsack.director import Director
from cloudsack.components import component_factory


class Base(object):

    def __init__(self, args):
        self.args = args

    def __call__(self):
        self.prepare()
        self.perform()

    def prepare(self):
        """Checks input and prepare appropriate input."""
        if not self.args.component_names:
            self.args.component_names = const.COMPONENTS


class Build(Base):

    def perform(self):
        for component_name in self.args.component_names:
            component_class = component_factory(component_name)
            component = component_class(self.args.config)
            director = Director(component)
            director.build()
            print('Successfully built: {}'.format(component_name))


class Launch(object):

    def __init__(self, args):
        self.__prepare(args)

    def __call__(self):
        self.perform()

    def __prepare(self, args):
        """Checks input and prepare appropriate input."""
        self.config = args.config
        if args.component_names:
            self.component_names = args.component_names
        else:
            self.component_names = const.COMPONENTS

    def perform(self):
        for component_name in self.component_names:
            component_class = component_factory(component_name)
            component = component_class(self.config)
            director = Director(component)
            director.launch()
            print('Successfully built: {}'.format(component_name))
