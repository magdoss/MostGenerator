package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.zikula.modulestudio.generator.extensions.Utils

class FrontController {
    @Inject extension Utils = new Utils()

    def generate(Application it, Boolean isBase) '''
        /**
         * Listener for the `frontcontroller.predispatch` event.
         *
         * Runs before the front controller does any work.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»\Zikula\Core\Event\GenericEvent«ENDIF» $event The event instance.
         */
        public static function preDispatch(«IF targets('1.3.5')»Zikula_Event«ELSE»\Zikula\Core\Event\GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::preDispatch($event);
            «ENDIF»
        }
    '''
}
