// Copyright 1997-2009 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/branches/Staff/bungi/OmniFocus-20090722-RankStank/OmniGroup/Frameworks/OmniBase/OBUtilities.h 115754 2009-07-14 20:57:07Z bungi $

// Extraced and trimmed down from OmniBase/OBUtilities.[hm]

#import <objc/runtime.h>

__private_extern__ IMP OBReplaceMethodImplementationWithSelectorOnClass(Class destClass, SEL oldSelector, Class sourceClass, SEL newSelector);
