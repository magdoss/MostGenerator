package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.util.text;

/*******************************************************************************
 * Copyright (c) 2009 IBM Corporation and others. All rights reserved. This
 * program and the accompanying materials are made available under the terms of
 * the Eclipse Public License v1.0 which accompanies this distribution, and is
 * available at http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors: IBM Corporation - initial API and implementation Zend
 * Technologies
 * 
 * 
 * 
 * Based on package org.eclipse.php.internal.core.util.text;
 * 
 *******************************************************************************/

import java.util.Iterator;

/**
 * @author seva, 2007
 * 
 */
public class StringUtils {

    private StringUtils() {
    }

    public static String implodeStrings(Iterable<String> strings, String glue) {
        final StringBuffer stringBuffer = new StringBuffer();
        for (final Iterator<String> i = strings.iterator(); i.hasNext();) {
            final String varClassName = i.next();
            stringBuffer.append(varClassName);
            if (i.hasNext()) {
                stringBuffer.append(glue);
            }
        }
        return stringBuffer.toString();
    }

}
