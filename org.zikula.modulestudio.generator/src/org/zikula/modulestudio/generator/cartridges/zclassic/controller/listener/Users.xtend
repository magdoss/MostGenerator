package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.zikula.modulestudio.generator.extensions.Utils

class Users {
    @Inject extension Utils = new Utils

    def generate(Application it, Boolean isBase) '''
        /**
         * Listener for the `module.users.config.updated` event.
         *
         * Occurs after the Users module configuration has been
         * updated via the administration interface.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event The event instance.
         */
        public static function configUpdated(«IF targets('1.3.5')»Zikula_Event«ELSE»GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::configUpdated($event);
            «ENDIF»
        }
        «IF !targets('1.3.5')»

            /**
             * Makes our handlers known to the event system.
             */
            public static function getSubscribedEvents()
            {
                return array(
                    'module.users.config.updated' => array('configUpdated', 5)
                );
            }
        «ENDIF»
    '''
}
