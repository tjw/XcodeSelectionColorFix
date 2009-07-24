// Copyright 1997-2009 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OBMethodReplacement.h"

#import <Foundation/Foundation.h>

// Extraced and trimmed down from OmniBase/OBUtilities.[hm]

static BOOL _OBRegisterMethod(IMP imp, Class cls, const char *types, SEL name)
{
    return class_addMethod(cls, name, imp, types);
}

static IMP OBReplaceMethodImplementationFromMethod(Class aClass, SEL oldSelector, Method newMethod)
{
    if (!newMethod) {
        NSLog(@"WARNING: OBReplaceMethodImplementationFromMethod got NULL method!");
        return NULL;
    }
    
    Method localMethod, superMethod;
    IMP oldImp = NULL;
    IMP newImp = method_getImplementation(newMethod);
    
    if ((localMethod = class_getInstanceMethod(aClass, oldSelector))) {
        {
            const char *oldSignature = method_getTypeEncoding(localMethod);
            const char *newSignature = method_getTypeEncoding(newMethod);
            
            if (strcmp(oldSignature, newSignature) != 0) {
                NSLog(@"WARNING: OBReplaceMethodImplementationFromMethod: Replacing %@ (signature: %s) with %@ (signature: %s)",
                      NSStringFromSelector(oldSelector), oldSignature,
                      NSStringFromSelector(method_getName(newMethod)), newSignature);
                return NULL;
            }
        }

	oldImp = method_getImplementation(localMethod);
        Class superCls = class_getSuperclass(aClass);
	superMethod = superCls ? class_getInstanceMethod(superCls, oldSelector) : NULL;
        
	if (superMethod == localMethod) {
	    // We are inheriting this method from the superclass.  We do *not* want to clobber the superclass's Method as that would replace the implementation on a greater scope than the caller wanted.  In this case, install a new method at this class and return the superclass's implementation as the old implementation (which it is).
	    _OBRegisterMethod(newImp, aClass, method_getTypeEncoding(localMethod), oldSelector);
	} else {
	    // Replace the method in place
//#ifdef OMNI_ASSERTIONS_ON
//            IMP previous = 
//#endif
            method_setImplementation(localMethod, newImp);
//            OBASSERT(oldImp == previous); // method_setImplementation is supposed to return the old implementation, but we already grabbed it.
	}
    }
    
    return oldImp;
}

IMP OBReplaceMethodImplementationWithSelectorOnClass(Class destClass, SEL oldSelector, Class sourceClass, SEL newSelector)
{
    return OBReplaceMethodImplementationFromMethod(destClass, oldSelector, class_getInstanceMethod(sourceClass, newSelector));
}
