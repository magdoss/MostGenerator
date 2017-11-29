/**
 * Copyright (c) 2007-2017 Axel Guckelsberger
 */
package org.zikula.modulestudio.generator.tests

class TestModels {

    def static simpleNews() {
        return '''
        application "SimpleNews" {
            documentation "Simple news extension"
            vendor "Guite"
            author "Axel Guckelsberger"
            email "info@guite.de"
            url "https://guite.de"
            prefix "sinew"
            entities {
                entity "article" leading {
                    nameMultiple "articles"
                    displayPattern "#title#"
                    fields {
                        string "title" {
                            length 200
                            sluggablePosition 1
                        }
                    }
                    actions {
                        mainAction "Index"
                    }
                },
                entity "image" leading {
                    nameMultiple "images"
                    displayPattern "#title#"
                    fields {
                        string "title" {
                            length 200
                            sluggablePosition 1
                        }
                    }
                    actions {
                        mainAction "Index"
                    }
                }
            }
        }
    '''
    }

    def static simpleNewsSerialised() {
        return '''application "SimpleNews" { documentation "Simple news extension" vendor "Guite" author "Axel Guckelsberger" email "info@guite.de" url "https://guite.de" prefix "sinew" entities { entity "article" leading { nameMultiple "articles" displayPattern "#title#" fields { string "title" { length 200 sluggablePosition 1 } } actions { mainAction "Index" } }, entity "image" leading { nameMultiple "images" displayPattern "#title#" fields { string "title" { length 200 sluggablePosition 1 } } actions { mainAction "Index" } } } }'''
    }
}
