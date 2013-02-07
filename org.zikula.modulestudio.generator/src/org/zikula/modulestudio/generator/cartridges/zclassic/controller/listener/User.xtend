package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import de.guite.modulestudio.metamodel.modulestudio.Entity
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class User {
    @Inject extension FormattingExtensions = new FormattingExtensions()
    @Inject extension ModelBehaviourExtensions = new ModelBehaviourExtensions()
    @Inject extension ModelExtensions = new ModelExtensions()
    @Inject extension NamingExtensions = new NamingExtensions()
    @Inject extension Utils = new Utils()

    def generate(Application it, Boolean isBase) '''
        /**
         * Listener for the `user.gettheme` event.
         *
         * Called during UserUtil::getTheme() and is used to filter the results.
         * Receives arg['type'] with the type of result to be filtered
         * and the $themeName in the $event->data which can be modified.
         * Must $event->stop«IF !targets('1.3.5')»Propagation«ENDIF»() if handler performs filter.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event The event instance.
         */
        public static function getTheme(«IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::getTheme($event);
            «ENDIF»
        }

        /**
         * Listener for the `user.account.create` event.
         *
         * Occurs after a user account is created. All handlers are notified.
         * It does not apply to creation of a pending registration.
         * The full user record created is available as the subject.
         * This is a storage-level event, not a UI event. It should not be used for UI-level actions such as redirects.
         * The subject of the event is set to the user record that was created.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event The event instance.
         */
        public static function create(«IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::create($event);
            «ENDIF»
        }

        /**
         * Listener for the `user.account.update` event.
         *
         * Occurs after a user is updated. All handlers are notified.
         * The full updated user record is available as the subject.
         * This is a storage-level event, not a UI event. It should not be used for UI-level actions such as redirects.
         * The subject of the event is set to the user record, with the updated values.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event The event instance.
         */
        public static function update(«IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::update($event);
            «ENDIF»
        }

        /**
         * Listener for the `user.account.delete` event.
         *
         * Occurs after a user is deleted from the system.
         * All handlers are notified.
         * The full user record deleted is available as the subject.
         * This is a storage-level event, not a UI event. It should not be used for UI-level actions such as redirects.
         * The subject of the event is set to the user record that is being deleted.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event The event instance.
         */
        public static function delete(«IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::delete($event);
            «ELSE»
                «IF hasStandardFieldEntities || hasUserFields»
                ModUtil::initOOModule('«appName»');

                $userRecord = $event->getSubject();
                $uid = $userRecord['uid'];
                $serviceManager = ServiceUtil::getManager();
                $entityManager = $serviceManager->getService('doctrine.entitymanager');
                «FOR entity : getAllEntities»«entity.userDelete»«ENDFOR»
                «ENDIF»
            «ENDIF»
        }
    '''

    def private userDelete(Entity it) '''
        «IF standardFields || hasUserFieldsEntity»

        $repo = $entityManager->getRepository('«entityClassName('', false)»');
        «IF standardFields»
            // delete all «nameMultiple.formatForDisplay» created by this user
            $repo->deleteCreator($uid);
            // note you could also do: $repo->updateCreator($uid, 2);

            // set last editor to admin (2) for all «nameMultiple.formatForDisplay» updated by this user
            $repo->updateLastEditor($uid, 2);
            // note you could also do: $repo->deleteLastEditor($uid);
        «ENDIF»
        «IF hasUserFieldsEntity»
            «FOR userField: getUserFieldsEntity»
                // set «userField.name.formatForDisplay» to guest (1) for all affected «nameMultiple.formatForDisplay»
                $repo->updateUserField('«userField.name.formatForCode»', $uid, 1);
            «ENDFOR»
        «ENDIF»
        «ENDIF»
    '''
}
