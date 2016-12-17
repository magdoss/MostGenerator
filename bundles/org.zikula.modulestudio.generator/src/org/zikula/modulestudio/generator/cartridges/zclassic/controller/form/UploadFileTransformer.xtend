package org.zikula.modulestudio.generator.cartridges.zclassic.controller.form

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class UploadFileTransformer {
    extension NamingExtensions = new NamingExtensions()
    extension Utils = new Utils()

    FileHelper fh = new FileHelper()

    def generate(Application it, IFileSystemAccess fsa) {
        generateClassPair(fsa, getAppSourceLibPath + 'Form/DataTransformer/UploadFileTransformer.php',
            fh.phpFileContent(it, transformerBaseImpl), fh.phpFileContent(it, transformerImpl)
        )
    }

    def private transformerBaseImpl(Application it) '''
        namespace «appNamespace»\Form\DataTransformer\Base;

        use ServiceUtil;
        use Symfony\Component\Form\DataTransformerInterface;
        use Symfony\Component\HttpFoundation\File\File;
        use Symfony\Component\HttpFoundation\File\UploadedFile;
        use Symfony\Component\HttpFoundation\Request;
        use «appNamespace»\Form\Type\Field\UploadType;
        use «appNamespace»\Helper\ControllerHelper;
        use «appNamespace»\UploadHandler;

        /**
         * Upload file transformer base class.
         *
         * This data transformer treats uploaded files.
         */
        abstract class AbstractUploadFileTransformer implements DataTransformerInterface
        {
            /**
             * @var UploadType
             */
            protected $formType = '';

            /**
             * @var Request
             */
            protected $request = '';

            /**
             * @var ControllerHelper
             */
            protected $controllerHelper = '';

            /**
             * @var UploadHandler
             */
            protected $uploadHandler = '';

            /**
             * @var string
             */
            protected $fieldName = '';

            /**
             * Constructor.
             *
             * @param UploadType $formType  The form type containing this transformer
             * @param string     $fieldName The form field name
             */
            public function __construct(UploadType $formType, $fieldName)
            {
                $this->formType = $formType;
                $this->request = ServiceUtil::get('request_stack')->getMasterRequest();
                $this->controllerHelper = ServiceUtil::get('«appService».controller_helper');
                $this->uploadHandler = ServiceUtil::get('«appService».upload_handler');
                $this->fieldName = $fieldName;
            }

            /**
             * Transforms a filename to the corresponding file object.
             *
             * @param string|File|null $filePath
             *
             * @return File|null
             */
            public function transform($filePath)
            {
                if (empty($filePath)) {
                    return null;
                }
                if ($filePath instanceof File) {
                    return $filePath;
                }

                return [$this->fieldName => new File($filePath)];
            }

            /**
             * Transforms an uploaded file back to the filename string.
             *
             * @param mixed $data Uploaded file or parent object (if file deletion checkbox has been provided)
             *
             * @return string
             */
            public function reverseTransform($data)
            {
                $deleteFile = false;
                $uploadedFile = null;

                if ($data instanceof UploadedFile) {
                    // no file deletion checkbox has been provided
                    $uploadedFile = $data;
                } else {
                    $children = $this->formType->getFormBuilder()->all();
                    foreach ($children as $child) {
                        $childForm = $child->getForm();
                        if (false !== strpos($childForm->getName(), 'DeleteFile')) {
                            $deleteFile = $childForm->getData();
                        } elseif ($childForm->getData() instanceof UploadedFile) {
                            $uploadedFile = $childForm->getData();
                        }
                    }
                }

                $entity = $this->formType->getEntity();
                $objectType = $entity->get_objectType();
                $fieldName = $this->fieldName;

                if (null === $uploadedFile) {
                    // check files array
                    $filesKey = '«appName.toLowerCase»_' . $objectType;
                    if ($this->request->files->has($filesKey)) {
                        $files = $this->request->files->get($filesKey);
                        if (isset($files[$fieldName]) && isset($files[$fieldName][$fieldName])) {
                            $uploadedFile = $files[$fieldName][$fieldName];
                        }
                    }
                }

                $oldFile = $entity[$fieldName];
                if (is_array($oldFile)) {
                    $oldFile = $oldFile[$fieldName];
                }

                // check if an existing file must be deleted
                $hasOldFile = !empty($oldFile);
                $hasBeenDeleted = !$hasOldFile;
                if ($hasOldFile && true === $deleteFile) {
                    // remove old upload file
                    $entity = $this->uploadHandler->deleteUploadFile($entity, $fieldName);
                    $hasBeenDeleted = true;
                }

                if (null === $uploadedFile) {
                    // no file has been uploaded
                    return null;
                }

                // new file has been uploaded; check if there is an old one to be deleted
                if ($hasOldFile && true !== $hasBeenDeleted) {
                    // remove old upload file (and image thumbnails)
                    $entity = $this->uploadHandler->deleteUploadFile($entity, $fieldName);
                }

                // do the actual upload (includes validation, physical file processing and reading meta data)
                $uploadResult = $this->uploadHandler->performFileUpload($objectType, $uploadedFile, $fieldName);

                $result = null;
                $metaData = [];
                if ($uploadResult['fileName'] != '') {
                    $result = $this->controllerHelper->getFileBaseFolder($this->formType->getEntity()->get_objectType(), $fieldName) . $uploadResult['fileName'];
                    $metaData = $uploadResult['metaData'];
                }

                // assign the upload file
                $setter = 'set' . ucfirst($fieldName);
                $entity->$setter(null !== $result ? new File($result) : $result);

                // assign the meta data
                $entity[$fieldName . 'Meta'] = $metaData;

                return $result;
            }
        }
    '''

    def private transformerImpl(Application it) '''
        namespace «appNamespace»\Form\DataTransformer;

        use «appNamespace»\Form\DataTransformer\Base\AbstractUploadFileTransformer;

        /**
         * Upload file transformer implementation class.
         *
         * This data transformer treats uploaded files.
         */
        class UploadFileTransformer extends AbstractUploadFileTransformer
        {
            // feel free to add your customisation here
        }
    '''
}