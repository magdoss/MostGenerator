package org.zikula.modulestudio.generator.cartridges.zclassic.controller.actionHandler

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import de.guite.modulestudio.metamodel.modulestudio.Controller
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils

/**
 * Upload processing functions for edit form handlers.
 */
class UploadProcessing {
    @Inject extension ModelExtensions = new ModelExtensions()
    @Inject extension Utils = new Utils()

    def generate(Controller it) {
        if (container.application.hasUploads)
            handleUploads(container.application)
    }

    def private handleUploads(Controller it, Application app) '''
        /**
         * Helper method to process upload fields
         */
        protected function handleUploads($formData, $existingObject)
        {
            if (!count($this->uploadFields)) {
                return $formData;
            }

            // initialise the upload handler
            $uploadManager = new «app.appName»_UploadHandler();
            $existingObjectData = $existingObject->toArray();

            // process all fields
            foreach ($this->uploadFields as $uploadField => $isMandatory) {
                // check if an existing file must be deleted
                $hasOldFile = (!empty($existingObjectData[$uploadField]));
                $hasBeenDeleted = !$hasOldFile;
                if ($this->mode != 'create') {
                    if (isset($formData[$uploadField . 'DeleteFile'])) {
                        if ($hasOldFile && $formData[$uploadField . 'DeleteFile'] === true) {
                            // remove upload file (and image thumbnails)
                            $existingObjectData = $uploadManager->deleteUploadFile($this->objectType, $existingObjectData, $uploadField);
                            if (empty($existingObjectData[$uploadField])) {
                                $existingObject[$uploadField] = '';
                            }
                        }
                        unset($formData[$uploadField . 'DeleteFile']);
                        $hasBeenDeleted = true;
                    }
                }

                // look whether a file has been provided
                if (!$formData[$uploadField] || $formData[$uploadField]['size'] == 0) {
                    // no file has been uploaded
                    unset($formData[$uploadField]);
                    // skip to next one
                    continue;
                }

                if ($hasOldFile && $hasBeenDeleted !== true && $this->mode != 'create') {
                    // remove old upload file (and image thumbnails)
                    $existingObjectData = $uploadManager->deleteUploadFile($this->objectType, $existingObjectData, $uploadField);
                    if (empty($existingObjectData[$uploadField])) {
                        $existingObject[$uploadField] = '';
                    }
                }

                // do the actual upload (includes validation, physical file processing and reading meta data)
                $uploadResult = $uploadManager->performFileUpload($this->objectType, $formData, $uploadField);
                // assign the upload file name
                $formData[$uploadField] = $uploadResult['fileName'];
                // assign the meta data
                $formData[$uploadField . 'Meta'] = $uploadResult['metaData'];

                // if current field is mandatory check if everything has been done
                if ($isMandatory && $formData[$uploadField] === false) {
                    // mandatory upload has not been completed successfully
                    return false;
                }

                // upload succeeded
            }

            return $formData;
        }
    '''
}
