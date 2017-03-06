#!/usr/bin/python
# -*- coding: utf-8 -*-


from cloudsack.operators import ImageBuilder
from cloudsack.operators import ServiceCreator


class Director(object):

    def __init__(self, component):
        self.component = component

    def build(self):
        image_builder = ImageBuilder(
            self.component.name,
            self.component.fqin,
            self.component.build_context,
        )
        image_builder.build()

    def launch(self):
        service_builder = ServiceCreator(
            self.component.name,
            self.component.build_service_context,
        )
        service_builder.build()
