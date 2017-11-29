/**
 * Copyright (c) 2007-2017 Axel Guckelsberger generated by Xtext 2.13.0
 */
package org.zikula.modulestudio.generator.tests;

import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.xtext.generator.IGenerator2;
import org.eclipse.xtext.parser.IEncodingProvider;
import org.eclipse.xtext.service.DispatchingProvider;
import org.eclipse.xtext.testing.GlobalRegistries;
import org.eclipse.xtext.testing.GlobalRegistries.GlobalStateMemento;
import org.eclipse.xtext.testing.IInjectorProvider;
import org.eclipse.xtext.testing.IRegistryConfigurator;
import org.zikula.modulestudio.generator.cartridges.MostGenerator;

import com.google.inject.Binder;
import com.google.inject.Guice;
import com.google.inject.Injector;

import de.guite.modulestudio.MostDslRuntimeModule;
import de.guite.modulestudio.MostDslStandaloneSetup;
import de.guite.modulestudio.encoding.MostDslEncodingProvider;

public class MostDslInjectorProvider implements IInjectorProvider, IRegistryConfigurator {

    protected GlobalStateMemento stateBeforeInjectorCreation;
    protected GlobalStateMemento stateAfterInjectorCreation;
    protected Injector injector;

    static {
        GlobalRegistries.initializeDefaults();
    }

    @Override
    public Injector getInjector() {
        if (injector == null) {
            stateBeforeInjectorCreation = GlobalRegistries.makeCopyOfGlobalState();
            this.injector = internalCreateInjector();
            stateAfterInjectorCreation = GlobalRegistries.makeCopyOfGlobalState();
        }
        return injector;
    }

    protected static Injector internalCreateInjector() {
        return new MostDslStandaloneSetup() {
            @Override
            public Injector createInjector() {
                return Guice.createInjector(createRuntimeModule());
            }
        }.createInjectorAndDoEMFRegistration();
    }

    protected static MostDslRuntimeModule createRuntimeModule() {
        // make it work also with Maven/Tycho and OSGI
        // see https://bugs.eclipse.org/bugs/show_bug.cgi?id=493672
        return new MostDslRuntimeModule() {
            @Override
            public ClassLoader bindClassLoaderToInstance() {
                return MostDslInjectorProvider.class.getClassLoader();
            }

            @Override
            public void configureRuntimeEncodingProvider(Binder binder) {
                binder.bind(IEncodingProvider.class).annotatedWith(DispatchingProvider.Runtime.class)
                        .to(MostDslEncodingProvider.class);
            }

            @Override
            public Class<? extends IGenerator2> bindIGenerator2() {
                return MostGenerator.class;
            }

            @Override
            public Class<? extends ResourceSet> bindResourceSet() {
                return ResourceSetImpl.class;
            }
        };
    }

    @Override
    public void restoreRegistry() {
        stateBeforeInjectorCreation.restoreGlobalState();
    }

    @Override
    public void setupRegistry() {
        getInjector();
        stateAfterInjectorCreation.restoreGlobalState();
    }
}