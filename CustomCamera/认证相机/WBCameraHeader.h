//
//  WBCameraHeader.h
//  CustomCamera
//
//  Created by mac on 15/4/30.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#ifndef CustomCamera_WBCameraHeader_h
#define CustomCamera_WBCameraHeader_h


#endif
#define SC_DEVICE_SIZE      [[UIScreen mainScreen] bounds].size
#define SC_BOTTOM_VIEW_HEIGHT 70.0f
#define SC_TOP_VIEW_HEIGHT 70.0f
#define WEAKSELF __weak __typeof(&*self)weakSelf_SC = self;

#if 1 // Set to 1 to enable debug logging
#define SCDLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define SCDLog(x, ...)
#endif