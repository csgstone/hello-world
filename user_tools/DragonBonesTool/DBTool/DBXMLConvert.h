//
//  DBXMLConvert.h
//  DragonBonesTool
//
//  Created by DuanHongbo on 15/6/10.
//
//

#ifndef __DragonBonesTool__DBXMLConvert__
#define __DragonBonesTool__DBXMLConvert__

#include <stdio.h>
#include <fstream>
extern "C" {
#include "pbc.h"
}
#include "DragonBonesHeaders.h"
#include "dbtinyxml2.h"

using namespace dragonBones;

class DBXMLConvert
{
public:
    DBXMLConvert();
public:
     bool toDragonBonesBinary(struct pbc_env* env,const XMLElement* date,struct pbc_wmessage * msg);
     bool toTextureAtlasBinary(struct pbc_env* env,const XMLElement* data,struct pbc_wmessage * msg);
    
private:
    void writeArmatureData(pbc_wmessage * msg,const XMLElement* data);
    void writeBoneData(pbc_wmessage * msg,const XMLElement* data);
    void writeSkinData(pbc_wmessage * msg,const XMLElement* data);
    void writeSlotData(pbc_wmessage * msg,const XMLElement* data);
    void writeDisplayData(pbc_wmessage * msg,const XMLElement* data);
    void writeAnimationData(pbc_wmessage * msg,const XMLElement* data);
    void writeTransform(pbc_wmessage * msg,const XMLElement* data);
    void writePoint(pbc_wmessage * msg,const XMLElement* data);
    void writeFrame(pbc_wmessage* msg,const XMLElement* data);
    void writeTransformTimeline(pbc_wmessage* msg,const XMLElement* data);
    void writeTransformFrame(pbc_wmessage* msg,const XMLElement* data);
    void writeColorTransform(pbc_wmessage* msg,const XMLElement* data);
    
    void writeTextureData(pbc_wmessage* msg,const XMLElement* data);
private:
    int _frameRate;
};

#endif /* defined(__DragonBonesTool__DBXMLConvert__) */
