//
//  DBXMLConvert.cpp
//  DragonBonesTool
//
//  Created by DuanHongbo on 15/6/10.
//
//

#include "DBXMLConvert.h"
#include "ConstValues.h"

using namespace std;

static bool getBoolean(const XMLElement &data, const char *key, bool defaultValue)
{
    if (data.FindAttribute(key))
    {
        const char *value = data.Attribute(key);
        
        if (
            strcmp(value, "0") == 0 ||
            strcmp(value, "NaN") == 0 ||
            strcmp(value, "") == 0 ||
            strcmp(value, "false") == 0 ||
            strcmp(value, "null") == 0 ||
            strcmp(value, "undefined") == 0
            )
        {
            return false;
        }
        else
        {
            return data.BoolAttribute(key);
        }
    }
    
    return defaultValue;
}

static float getNumber(const XMLElement &data, const char *key, float defaultValue, float nanValue)
{
    if (data.FindAttribute(key))
    {
        const char *value = data.Attribute(key);
        
        if (
            strcmp(value, "NaN") == 0 ||
            strcmp(value, "") == 0 ||
            strcmp(value, "false") == 0 ||
            strcmp(value, "null") == 0 ||
            strcmp(value, "undefined") == 0
            )
        {
            return nanValue;
        }
        else
        {
            return data.FloatAttribute(key);
        }
    }
    
    return defaultValue;
}

DBXMLConvert::DBXMLConvert()
:_frameRate(24)
{
}

bool DBXMLConvert::toDragonBonesBinary(struct pbc_env* env,const XMLElement* data,struct pbc_wmessage * msg)
{
    string version = data->Attribute(ConstValues::A_VERSION.c_str());
    _frameRate = data->IntAttribute(ConstValues::A_FRAME_RATE.c_str());
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    
    pbc_wmessage_string(msg, "version", version.c_str(),-1);
    pbc_wmessage_string(msg, "name", name.c_str(), -1);
    pbc_wmessage_integer(msg, "frameRate", _frameRate, 0);
    
    
    for (const XMLElement *armatureXML = data->FirstChildElement(ConstValues::ARMATURE.c_str()); armatureXML; armatureXML = armatureXML->NextSiblingElement(ConstValues::ARMATURE.c_str()))
    {
        struct pbc_wmessage * armatureDataMsg = pbc_wmessage_message(msg , "armatureDataList");
        writeArmatureData(armatureDataMsg,armatureXML);
    }
    return true;
}

void DBXMLConvert::writeArmatureData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    
    pbc_wmessage_string(msg, "name", name.c_str(), -1);
    
    
    for (const XMLElement *boneXML = data->FirstChildElement(ConstValues::BONE.c_str()); boneXML; boneXML = boneXML->NextSiblingElement(ConstValues::BONE.c_str()))
    {
        struct pbc_wmessage * boneMsg = pbc_wmessage_message(msg , "boneDataList");
        writeBoneData(boneMsg, boneXML);
    }
    
    
    for (const XMLElement *skinXML = data->FirstChildElement(ConstValues::SKIN.c_str()); skinXML; skinXML = skinXML->NextSiblingElement(ConstValues::SKIN.c_str()))
    {
        struct pbc_wmessage * skinMsg = pbc_wmessage_message(msg , "skinDataList");
        writeSkinData(skinMsg, skinXML);
    }

    
    for (const XMLElement *animationXML = data->FirstChildElement(ConstValues::ANIMATION.c_str()); animationXML; animationXML = animationXML->NextSiblingElement(ConstValues::ANIMATION.c_str()))
    {
        struct pbc_wmessage * aniMsg = pbc_wmessage_message(msg , "animationDataList");
        writeAnimationData(aniMsg,animationXML);
    }
}

void DBXMLConvert::writeBoneData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    pbc_wmessage_string(msg, "name", name.c_str(), -1);
    
    const char *parent = data->Attribute(ConstValues::A_PARENT.c_str());
    
    if(parent)
        pbc_wmessage_string(msg, "parent",parent, -1);
    
    float length = data->FloatAttribute(ConstValues::A_LENGTH.c_str());
    pbc_wmessage_real(msg, "length", length);
    
    bool inheritRotation = getBoolean(*data, ConstValues::A_INHERIT_ROTATION.c_str(), true);
    bool inheritScale = getBoolean(*data, ConstValues::A_INHERIT_SCALE.c_str(), false);
    
    pbc_wmessage_integer(msg, "inheritRotation", inheritRotation?1:0, 0);
    pbc_wmessage_integer(msg, "inheritScale", inheritScale?1:0, 0);
    
    
    const XMLElement *transformXML = data->FirstChildElement(ConstValues::TRANSFORM.c_str());
    if (transformXML)
    {
        struct pbc_wmessage * globalMsg = pbc_wmessage_message(msg , "global");
        writeTransform(globalMsg, transformXML);
    }
}


void DBXMLConvert::writeSkinData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    pbc_wmessage_string(msg, "name", name.c_str(),-1);
    
    for (const XMLElement *slotXML = data->FirstChildElement(ConstValues::SLOT.c_str()); slotXML; slotXML = slotXML->NextSiblingElement(ConstValues::SLOT.c_str()))
    {
        struct pbc_wmessage * slotmsg = pbc_wmessage_message(msg , "slotDataList");
        writeSlotData(slotmsg,slotXML);
    }
}


void DBXMLConvert::writeSlotData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    string parent = data->Attribute(ConstValues::A_PARENT.c_str());
    float zOrder = data->FloatAttribute(ConstValues::A_Z_ORDER.c_str());
    
    BlendMode blendMode = BlendMode::BM_NORMAL;
    if (data->FindAttribute(ConstValues::A_BLENDMODE.c_str()))
    {
        blendMode = getBlendModeByString(data->Attribute(ConstValues::A_BLENDMODE.c_str()));
    }
    
    pbc_wmessage_string(msg, "name", name.c_str(), -1);
    if(!parent.empty())
        pbc_wmessage_string(msg, "parent", parent.c_str(),-1);
    
    pbc_wmessage_real(msg, "zOrder", zOrder);
    pbc_wmessage_integer(msg, "blendMode", (int)blendMode, 0);
    
    
    for (const XMLElement *displayXML = data->FirstChildElement(ConstValues::DISPLAY.c_str()); displayXML; displayXML = displayXML->NextSiblingElement(ConstValues::DISPLAY.c_str()))
    {
        struct pbc_wmessage * displayMsg = pbc_wmessage_message(msg , "displayDataList");
        writeDisplayData(displayMsg, displayXML);
    }
}


void DBXMLConvert::writeDisplayData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    DisplayType type = getDisplayTypeByString(data->Attribute(ConstValues::A_TYPE.c_str()));
    
    
    pbc_wmessage_string(msg, "name", name.c_str(),-1);
    pbc_wmessage_integer(msg, "type", (int)type, (int)DisplayType::DT_IMAGE);
    
    const XMLElement *scalingGridXML = data->FirstChildElement(ConstValues::SCALING_GRID.c_str());
    if (scalingGridXML)
    {
        pbc_wmessage_integer(msg, "scalingGrid", 1, 0);
        pbc_wmessage_integer(msg, "scalingGridLeft", scalingGridXML->IntAttribute(ConstValues::A_LEFT.c_str()), 0);
        pbc_wmessage_integer(msg, "scalingGridRight",scalingGridXML->IntAttribute(ConstValues::A_RIGHT.c_str()), 0);
        pbc_wmessage_integer(msg, "scalingGridTop", scalingGridXML->IntAttribute(ConstValues::A_TOP.c_str()), 0);
        pbc_wmessage_integer(msg, "scalingGridBottom", scalingGridXML->IntAttribute(ConstValues::A_BOTTOM.c_str()), 0);
    }
    else
    {
        pbc_wmessage_integer(msg, "scalingGrid", 0, 0);
    }
    
    const XMLElement *transformXML = data->FirstChildElement(ConstValues::TRANSFORM.c_str());
    if (transformXML)
    {
        struct pbc_wmessage * transformMsg = pbc_wmessage_message(msg , "transform");
        writeTransform(transformMsg, transformXML);

        struct pbc_wmessage * pivotMsg = pbc_wmessage_message(msg , "pivot");
        writePoint(pivotMsg, transformXML);
    }
}

void DBXMLConvert::writeAnimationData(pbc_wmessage * msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    int duration = data->IntAttribute(ConstValues::A_DURATION.c_str());
    int playTimes = data->IntAttribute(ConstValues::A_LOOP.c_str());
    float fadeTime = data->FloatAttribute(ConstValues::A_FADE_IN_TIME.c_str());
    float scale = getNumber(*data, ConstValues::A_SCALE.c_str(), 1.f, 1.f);
    float tweenEasing = getNumber(*data, ConstValues::A_TWEEN_EASING.c_str(), USE_FRAME_TWEEN_EASING, USE_FRAME_TWEEN_EASING);
    
    bool autoTween = getBoolean(*data, ConstValues::A_AUTO_TWEEN.c_str(), true);
    
    pbc_wmessage_string(msg, "name", name.c_str(), -1);
    pbc_wmessage_integer(msg, "duration", duration, 0);
    pbc_wmessage_integer(msg, "playTimes", playTimes, 0);
    pbc_wmessage_real(msg, "fadeTime", fadeTime);
    pbc_wmessage_real(msg, "scale", scale);
    pbc_wmessage_real(msg, "tweenEasing", tweenEasing);
    pbc_wmessage_integer(msg, "autoTween", autoTween?1:0, 0);
    
    
    for (const XMLElement *frameXML = data->FirstChildElement(ConstValues::FRAME.c_str()); frameXML; frameXML = frameXML->NextSiblingElement(ConstValues::FRAME.c_str()))
    {
        struct pbc_wmessage * frameMsg = pbc_wmessage_message(msg , "frameList");
        writeFrame(frameMsg,frameXML);
    }

    
    for (const XMLElement *timelineXML = data->FirstChildElement(ConstValues::TIMELINE.c_str()); timelineXML; timelineXML = timelineXML->NextSiblingElement(ConstValues::TIMELINE.c_str()))
    {
        struct pbc_wmessage * timelineMsg = pbc_wmessage_message(msg , "timelineList");
        writeTransformTimeline(timelineMsg, timelineXML);
    }
}

void DBXMLConvert::writeTransformTimeline(pbc_wmessage* msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    float scale = data->FloatAttribute(ConstValues::A_SCALE.c_str());
    float offset = data->FloatAttribute(ConstValues::A_OFFSET.c_str());
    
    pbc_wmessage_string(msg, "name", name.c_str(),-1);
    pbc_wmessage_real(msg, "scale", scale);
    pbc_wmessage_real(msg, "offset", offset);
    
    for (const XMLElement *frameXML = data->FirstChildElement(ConstValues::FRAME.c_str()); frameXML; frameXML = frameXML->NextSiblingElement(ConstValues::FRAME.c_str()))
    {
        struct pbc_wmessage * frameMsg = pbc_wmessage_message(msg , "frameList");
        writeTransformFrame(frameMsg,frameXML);
    }
}

void DBXMLConvert::writeFrame(pbc_wmessage* msg,const XMLElement* data)
{
    int duration = data->IntAttribute(ConstValues::A_DURATION.c_str());
    
    pbc_wmessage_integer(msg, "duration", duration, 0);
    
    if (data->FindAttribute(ConstValues::A_ACTION.c_str()))
    {
        pbc_wmessage_string(msg, "action", data->Attribute(ConstValues::A_ACTION.c_str()),-1);
    }
    
    
    if (data->FindAttribute(ConstValues::A_EVENT.c_str()))
    {
        pbc_wmessage_string(msg, "event",data->Attribute(ConstValues::A_EVENT.c_str()),-1);
    }
    
    if (data->FindAttribute(ConstValues::A_SOUND.c_str()))
    {
        pbc_wmessage_string(msg, "sound", data->Attribute(ConstValues::A_SOUND.c_str()), -1);
    }
}



void DBXMLConvert::writeTransformFrame(pbc_wmessage* msg,const XMLElement* data)
{
    writeFrame(msg, data);
  
    bool visible = !getBoolean(*data, ConstValues::A_HIDE.c_str(), false);
    float tweenEasing = getNumber(*data, ConstValues::A_TWEEN_EASING.c_str(), AUTO_TWEEN_EASING, NO_TWEEN_EASING);
    int tweenRotate = data->IntAttribute(ConstValues::A_TWEEN_ROTATE.c_str());
    bool tweenScale = getBoolean(*data, ConstValues::A_TWEEN_SCALE.c_str(), true);
    int displayIndex = data->IntAttribute(ConstValues::A_DISPLAY_INDEX.c_str());
    float zOrder = getNumber(*data, ConstValues::A_Z_ORDER.c_str(), 0.f, 0.f);
    
    pbc_wmessage_integer(msg, "visible", visible?1:0, 0);
    pbc_wmessage_real(msg, "tweenEasing", tweenEasing);
    pbc_wmessage_integer(msg, "tweenRotate", tweenRotate?1:0, 0);
    pbc_wmessage_integer(msg, "tweenScale", tweenScale?1:0, 0);
    pbc_wmessage_integer(msg, "displayIndex", displayIndex, 0);
    pbc_wmessage_real(msg, "zOrder", zOrder);
    
    
    const XMLElement *transformXML = data->FirstChildElement(ConstValues::TRANSFORM.c_str());
    if (transformXML)
    {
        struct pbc_wmessage * globalMsg = pbc_wmessage_message(msg , "global");
        writeTransform(globalMsg, transformXML);
        
        struct pbc_wmessage * pivotMsg = pbc_wmessage_message(msg , "pivot");
        writePoint(pivotMsg, transformXML);
    }
    
  
    struct pbc_wmessage * scaleOffsetMsg = pbc_wmessage_message(msg , "scaleOffset");
    pbc_wmessage_real(scaleOffsetMsg, "x", getNumber(*data, ConstValues::A_SCALE_X_OFFSET.c_str(), 0.f, 0.f));
    pbc_wmessage_real(scaleOffsetMsg, "y", getNumber(*data, ConstValues::A_SCALE_Y_OFFSET.c_str(), 0.f, 0.f));
    
    
    const XMLElement *colorTransformXML = data->FirstChildElement(ConstValues::COLOR_TRANSFORM.c_str());
    if (colorTransformXML)
    {
        struct pbc_wmessage * colorMsg = pbc_wmessage_message(msg , "color");
        writeColorTransform(colorMsg,colorTransformXML);
    }
}

void DBXMLConvert::writeColorTransform(pbc_wmessage* msg,const XMLElement* data)
{
    int alphaOffset = data->IntAttribute(ConstValues::A_ALPHA_OFFSET.c_str());
    int redOffset = data->IntAttribute(ConstValues::A_RED_OFFSET.c_str());
    int greenOffset = data->IntAttribute(ConstValues::A_GREEN_OFFSET.c_str());
    int blueOffset = data->IntAttribute(ConstValues::A_BLUE_OFFSET.c_str());
    float alphaMultiplier = data->FloatAttribute(ConstValues::A_ALPHA_MULTIPLIER.c_str())* 0.01f;
    float redMultiplier = data->FloatAttribute(ConstValues::A_RED_MULTIPLIER.c_str())* 0.01f;;
    float greenMultiplier = data->FloatAttribute(ConstValues::A_GREEN_MULTIPLIER.c_str())* 0.01f;
    float blueMultiplier = data->FloatAttribute(ConstValues::A_BLUE_MULTIPLIER.c_str())* 0.01f;
    
    pbc_wmessage_integer(msg, "alphaOffset", alphaOffset, 0);
    pbc_wmessage_integer(msg, "redOffset", redOffset, 0);
    pbc_wmessage_integer(msg, "greenOffset", greenOffset, 0);
    pbc_wmessage_integer(msg, "blueOffset", blueOffset, 0);
    pbc_wmessage_real(msg, "alphaMultiplier", alphaMultiplier);
    pbc_wmessage_real(msg, "redMultiplier", redMultiplier);
    pbc_wmessage_real(msg, "greenMultiplier", greenMultiplier);
    pbc_wmessage_real(msg, "blueMultiplier", blueMultiplier);

}

void DBXMLConvert::writeTransform(pbc_wmessage * msg,const XMLElement* data)
{
    pbc_wmessage_real(msg, "x", data->FloatAttribute(ConstValues::A_X.c_str()));
    pbc_wmessage_real(msg, "y", data->FloatAttribute(ConstValues::A_Y.c_str()));
    pbc_wmessage_real(msg, "skewX", data->FloatAttribute(ConstValues::A_SKEW_X.c_str()));
    pbc_wmessage_real(msg, "skewY", data->FloatAttribute(ConstValues::A_SKEW_Y.c_str()));
    pbc_wmessage_real(msg, "scaleX", data->FloatAttribute(ConstValues::A_SCALE_X.c_str()));
    pbc_wmessage_real(msg, "scaleY", data->FloatAttribute(ConstValues::A_SCALE_Y.c_str()));
}


void DBXMLConvert::writePoint(pbc_wmessage * msg,const XMLElement* data)
{
    pbc_wmessage_real(msg, "x", data->FloatAttribute(ConstValues::A_PIVOT_X.c_str()));
    pbc_wmessage_real(msg, "y", data->FloatAttribute(ConstValues::A_PIVOT_Y.c_str()));
}


bool DBXMLConvert::toTextureAtlasBinary(struct pbc_env* env,const XMLElement* data,struct pbc_wmessage * msg)
{
    const char* name = data->Attribute(ConstValues::A_NAME.c_str());
    const char* imagePath = data->Attribute(ConstValues::A_IMAGE_PATH.c_str());
    
    pbc_wmessage_string(msg, "name", name ? name : "",-1);
    pbc_wmessage_string(msg, "imagePath", imagePath ? imagePath : "",-1);
    
    
    for (const XMLElement *textureXML = data->FirstChildElement(ConstValues::SUB_TEXTURE.c_str()); textureXML; textureXML = textureXML->NextSiblingElement(ConstValues::SUB_TEXTURE.c_str()))
    {
        struct pbc_wmessage * textureMsg = pbc_wmessage_message(msg , "textureDataList");
        writeTextureData(textureMsg,textureXML);
    }

    return true;
}

void DBXMLConvert::writeTextureData(pbc_wmessage* msg,const XMLElement* data)
{
    string name = data->Attribute(ConstValues::A_NAME.c_str());
    bool rotated = data->BoolAttribute(ConstValues::A_ROTATED.c_str());
    
    
    pbc_wmessage_string(msg, "name", name.c_str(),-1);
    pbc_wmessage_integer(msg, "rotated", rotated?1:0, 0);
    
    struct pbc_wmessage * regionMsg = pbc_wmessage_message(msg , "region");
    pbc_wmessage_real(regionMsg, "x", data->FloatAttribute(ConstValues::A_X.c_str()));
    pbc_wmessage_real(regionMsg, "y", data->FloatAttribute(ConstValues::A_Y.c_str()));
    pbc_wmessage_real(regionMsg, "width", data->FloatAttribute(ConstValues::A_WIDTH.c_str()) );
    pbc_wmessage_real(regionMsg, "height", data->FloatAttribute(ConstValues::A_HEIGHT.c_str()));
    
    
    
    struct pbc_wmessage * frameMsg = pbc_wmessage_message(msg , "frame");
    pbc_wmessage_real(frameMsg, "width", data->FloatAttribute(ConstValues::A_FRAME_WIDTH.c_str()));
    pbc_wmessage_real(frameMsg, "height", data->FloatAttribute(ConstValues::A_FRAME_HEIGHT.c_str()));
    pbc_wmessage_real(frameMsg, "x", data->FloatAttribute(ConstValues::A_FRAME_X.c_str()));
    pbc_wmessage_real(frameMsg, "y", data->FloatAttribute(ConstValues::A_FRAME_Y.c_str()));

}
