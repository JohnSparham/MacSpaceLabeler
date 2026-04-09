#ifndef SpaceLabeler_Bridging_Header_h
#define SpaceLabeler_Bridging_Header_h

#include <CoreGraphics/CoreGraphics.h>

// Private CoreGraphics SPI for Space management
extern int _CGSDefaultConnection(void);
extern uint64_t CGSGetActiveSpace(int cid);
extern CFArrayRef _Nullable CGSCopyManagedDisplaySpaces(int cid) CF_RETURNS_RETAINED;

#endif
