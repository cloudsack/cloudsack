#!/usr/bin/python
# -*- coding: utf-8 -*-


from cloudsack import operators


class Director(object):

    def __init__(self, component):
        self.component = component

    def build(self):
        image_builder = operators.ImageBuilder(
            self.component.name,
            self.component.fqin,
            self.component.build_context,
        )
        image_builder.build()

    def launch(self):
        service_creator = operators.ServiceCreator(
            self.component.name,
            self.component.build_service_context,
        )
        service_creator.build()

        job_creator = operators.JobCreator(
            self.component.name,
            self.component.create_job_context,
        )
        job_creator.create()
