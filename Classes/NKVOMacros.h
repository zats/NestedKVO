//
//  NKVOMacros.h
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#ifndef NestedKVO_NKVOMacros_h
#define NestedKVO_NKVOMacros_h

#ifdef DEBUG
#define NKVOKeyPath(object, keyPath) ({ if (NO) { (void)((object).keyPath); } @#keyPath; })
#else
#define NKVOKeyPath(object, keyPath) ({ @#keyPath; })
#endif

#define NKVOSelfKeyPath(keyPath) NKVOKeyPath(self, keyPath)
#define NKVOTypedKeyPath(ObjectClass, keyPath) NKVOKeyPath(((ObjectClass *)nil), keyPath)
#define NKVOProtocolKeyPath(Protocol, keyPath) NKVOKeyPath(((id <Protocol>)nil), keyPath)

#endif
