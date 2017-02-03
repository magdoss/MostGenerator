package org.zikula.modulestudio.generator.extensions.transformation

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.EntityWorkflowType
import de.guite.modulestudio.metamodel.IpAddressScope
import de.guite.modulestudio.metamodel.ModuleStudioFactory
import de.guite.modulestudio.metamodel.StringField
import de.guite.modulestudio.metamodel.UploadField
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions

/**
 * This class adds primary key fields to all entities of an application.
 */
class PersistenceTransformer {

    /**
     * Extension methods for controllers.
     */
    extension ControllerExtensions = new ControllerExtensions

    /**
     * Extension methods for generator settings.
     */
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions

    /**
     * Extension methods for formatting names.
     */
    extension FormattingExtensions = new FormattingExtensions

    /**
     * Extension methods related to behavioural model extensions.
     */
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions

    /**
     * Extension methods related to the model layer.
     */
    extension ModelExtensions = new ModelExtensions

    /**
     * Transformation entry point consuming the application instance.
     *
     * @param it The given {@link Application} instance.
     */
    def modify(Application it) {
        println('Starting model transformation')
        // handle all entities
        for (entity : getAllEntities) {
            entity.handleEntity
        }

        addWorkflowSettings
        addViewSettings
        addImageSettings
        addGeoSettings
    }

    /**
     * Transformation processing for a single entity.
     *
     * @param it The currently treated {@link Entity} instance.
     */
    def private void handleEntity(Entity it) {
        //println('Transforming entity ' + name)
        //println('Field size before: ' + fields.size + ' fields')
        if (getPrimaryKeyFields.empty) {
            addPrimaryKey
        }
        //println('Added primary key, field size now: ' + fields.size + ' fields')

        addWorkflowState

        // make optional upload fields nullable, too
        for (field : fields.filter(UploadField).filter[f|!f.mandatory]) {
            field.nullable = true
        }

        // add nospace constraint if required
        for (field : fields.filter(StringField)) {
            if (field.bic || field.country || field.currency || field.language || field.locale || field.ipAddress != IpAddressScope.NONE || field.htmlcolour || field.uuid) {
                field.nospace = true
            }
        }
    }

    /**
     * Adds a primary key to a given entity.
     * 
     * @param entity The given {@link Entity} instance.
     */
    def private addPrimaryKey(Entity entity) {
        entity.fields.add(0, createIdColumn('', true))
    }

    /**
     * Creates a new identifier field.
     *
     * @param colName The column name.
     * @param isPrimary Whether the field should be primary or not.
     * @return IntegerField The created column object.
     */
    def private createIdColumn(String colName, Boolean isPrimary) {
        val factory = ModuleStudioFactory.eINSTANCE
        val idField = factory.createIntegerField => [
            name = if (isPrimary) 'id' else colName.formatForCode + '_id'
            length = 9
            primaryKey = isPrimary
            unique = isPrimary
        ]
        idField
    }

    /**
     * Adds a list field for the workflow state to a given entity.
     * 
     * @param entity The given {@link Entity} instance.
     */
    def private addWorkflowState(Entity entity) {
        val factory = ModuleStudioFactory.eINSTANCE
        val listField = factory.createListField => [
            name = 'workflowState'
            documentation = 'the current workflow state'
            length = 20
            defaultValue = 'initial'
            multiple = false
        ]
        listField.items += factory.createListFieldItem => [
            name = 'Initial'
            value = 'initial'
            documentation = 'Pseudo-state for content which is just created and not persisted yet.'
            ^default = true
        ]

        if (entity.ownerPermission) {
            listField.items += factory.createListFieldItem => [
                name = 'Deferred'
                value = 'deferred'
                documentation = 'Content has not been submitted yet or has been waiting, but was rejected.'
            ]
        }

        if (entity.workflow != EntityWorkflowType.NONE) {
            listField.items += factory.createListFieldItem => [
                name = 'Waiting'
                value = 'waiting'
                documentation = 'Content has been submitted and waits for approval.'
            ]

            if (entity.workflow == EntityWorkflowType.ENTERPRISE) {
                listField.items += factory.createListFieldItem => [
                    name = 'Accepted'
                    value = 'accepted'
                    documentation = 'Content has been submitted and accepted, but still waits for approval.'
                ]
            }
        }

        listField.items += factory.createListFieldItem => [
            name = 'Approved'
            value = 'approved'
            documentation = 'Content has been approved and is available online.'
        ]

        if (entity.hasTray) {
            listField.items += factory.createListFieldItem => [
                name = 'Suspended'
                value = 'suspended'
                documentation = 'Content has been approved, but is temporarily offline.'
            ]
        }

        if (entity.hasArchive) {
            listField.items += factory.createListFieldItem => [
                name = 'Archived'
                value = 'archived'
                documentation = 'Content has reached the end and became archived.'
            ]
        }

        if (entity.softDeleteable) {
            listField.items += factory.createListFieldItem => [
                name = 'Trashed'
                value = 'trashed'
                documentation = 'Content has been marked as deleted, but is still persisted in the database.'
            ]
        }

        listField.items += factory.createListFieldItem => [
            name = 'Deleted'
            value = 'deleted'
            documentation = 'Pseudo-state for content which has been deleted from the database.'
        ]

        entity.fields.add(1, listField)

        val wfIndex = factory.createEntityIndex => [
            name = 'workflowStateIndex'
        ]
        wfIndex.items += factory.createEntityIndexItem => [
            name = 'workflowState'
        ]

        entity.indexes += wfIndex
    }

    def private addWorkflowSettings(Application it) {
        val entitiesWithWorkflow = getAllEntities.filter[workflow != EntityWorkflowType.NONE]
        if (entitiesWithWorkflow.empty) {
            return
        }

        val varContainer = createVarContainerForWorkflowSettings
        val factory = ModuleStudioFactory.eINSTANCE

        for (entity : entitiesWithWorkflow) {
            varContainer.vars += factory.createIntVar => [
                name = 'moderationGroupFor' + entity.nameMultiple.formatForCodeCapital
                value = '2' // use admin group (gid=2) as fallback
                documentation = 'Used to determine moderator user accounts for sending email notifications.'
            ]
            if (entity.workflow == EntityWorkflowType.ENTERPRISE) {
                varContainer.vars += factory.createIntVar => [
                    name = 'superModerationGroupFor' + entity.nameMultiple.formatForCodeCapital
                    value = '2' // use admin group (gid=2) as fallback
                    documentation = 'Used to determine moderator user accounts for sending email notifications.'
                ]
            }
        }

        variables += varContainer
    }

    def private addViewSettings(Application it) {
        val entitiesWithView = getAllEntities.filter[hasViewAction]
        if (entitiesWithView.empty) {
            return
        }

        val varContainer = createVarContainerForViewSettings
        val factory = ModuleStudioFactory.eINSTANCE

        for (entity : entitiesWithView) {
            varContainer.vars += factory.createIntVar => [
                name = entity.name.formatForCode + 'EntriesPerPage'
                value = '10'
                documentation = 'The amount of ' + entity.nameMultiple.formatForDisplay + ' shown per page'
            ]
            if (generateAccountApi && entity.standardFields) {
                varContainer.vars += factory.createBoolVar => [
                    name = 'linkOwn' + entity.nameMultiple.formatForCodeCapital + 'OnAccountPage'
                    value = 'true'
                    documentation = 'Whether to add a link to ' + entity.nameMultiple.formatForDisplay + ' of the current user on his account page'
                ]
            }
        }

        variables += varContainer
    }

    def private addImageSettings(Application it) {
        if (!hasImageFields) {
            return
        }

        val varContainer = createVarContainerForImageSettings
        val factory = ModuleStudioFactory.eINSTANCE

        val entitiesWithImageUploads = getAllEntities.filter[hasImageFieldsEntity]
        for (entity : entitiesWithImageUploads) {
            for (imageUploadField : entity.imageFieldsEntity) {
                val fieldSuffix = entity.name.formatForCodeCapital + imageUploadField.name.formatForCodeCapital
                varContainer.vars += factory.createBoolVar => [
                    name = 'enableShrinkingFor' + fieldSuffix
                    value = 'false'
                    documentation = 'Whether to enable shrinking huge images to maximum dimensions. Stores downscaled version of the original image.'
                ]
                varContainer.vars += factory.createIntVar => [
                    name = 'shrinkWidth' + fieldSuffix
                    value = '800'
                    documentation = 'The maximum image width in pixels.'
                ]
                varContainer.vars += factory.createIntVar => [
                    name = 'shrinkHeight' + fieldSuffix
                    value = '600'
                    documentation = 'The maximum image height in pixels.'
                ]
                val thumbModeVar = factory.createListVar => [
                    name = 'thumbnailMode' + fieldSuffix
                    value = 'inset'
                    documentation = 'Thumbnail mode (inset or outbound).'
                ]
                thumbModeVar.items += factory.createListVarItem => [
                    name = 'Inset'
                    ^default = true
                ]
                thumbModeVar.items += factory.createListVarItem => [
                    name = 'Outbound'
                ]
                varContainer.vars += thumbModeVar
                for (action : #['view', 'display', 'edit']) {
                    if ((action == 'view' && entity.hasViewAction) || (action == 'display' && entity.hasDisplayAction) || (action == 'edit' && entity.hasEditAction)) {
                        varContainer.vars += factory.createIntVar => [
                            name = 'thumbnailWidth' + fieldSuffix + action.toFirstUpper
                            value = if (action == 'view') '32' else '240'
                            documentation = 'Thumbnail width on ' + action + ' pages in pixels.'
                        ]
                        varContainer.vars += factory.createIntVar => [
                            name = 'thumbnailHeight' + fieldSuffix + action.toFirstUpper
                            value = if (action == 'view') '24' else '180'
                            documentation = 'Thumbnail height on ' + action + ' pages in pixels.'
                        ]
                    }
                }
            }
        }

        variables += varContainer
    }

    def private addGeoSettings(Application it) {
        if (!hasGeographical) {
            return
        }

        val varContainer = createVarContainerForGeoSettings
        val factory = ModuleStudioFactory.eINSTANCE

        varContainer.vars += factory.createTextVar => [
            name = 'googleMapsApiKey'
            value = ''
            documentation = 'The API key required for Google Maps.'
        ]

        for (entity : getGeographicalEntities) {
            varContainer.vars += factory.createBoolVar => [
                name = 'enable' + entity.name.formatForCodeCapital + 'GeoLocation'
                value = 'false'
                documentation = 'Whether to enable geo location functionality for ' + entity.nameMultiple.formatForDisplay + ' or not.'
            ]
        }

        variables += varContainer
    }

    def private createVarContainerForWorkflowSettings(Application it) {
        val newSortNumber = getNextVarContainerSortNumber
        ModuleStudioFactory.eINSTANCE.createVariables => [
            name = 'Moderation'
            documentation = 'Here you can assign moderation groups for enhanced workflow actions.'
            sortOrder = newSortNumber
        ]
    }

    def private createVarContainerForViewSettings(Application it) {
        val newSortNumber = getNextVarContainerSortNumber
        ModuleStudioFactory.eINSTANCE.createVariables => [
            name = 'ListViews'
            documentation = 'Here you can configure parameters for list views.'
            sortOrder = newSortNumber
        ]
    }

    def private createVarContainerForImageSettings(Application it) {
        val newSortNumber = getNextVarContainerSortNumber
        ModuleStudioFactory.eINSTANCE.createVariables => [
            name = 'Images'
            documentation = 'Here you can define several options for image handling.'
            sortOrder = newSortNumber
        ]
    }

    def private createVarContainerForGeoSettings(Application it) {
        val newSortNumber = getNextVarContainerSortNumber
        ModuleStudioFactory.eINSTANCE.createVariables => [
            name = 'Geo'
            documentation = 'Here you can define settings related to geographical features.'
            sortOrder = newSortNumber
        ]
    }

    def private getNextVarContainerSortNumber(Application it) {
        var lastVarContainerSortNumber = 0
        if (!variables.empty) {
            lastVarContainerSortNumber = variables.sortBy[sortOrder].reverseView.head.sortOrder
        }

        val newSortNumber = lastVarContainerSortNumber + 1

        newSortNumber
    }
}
