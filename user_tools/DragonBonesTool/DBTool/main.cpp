//
//  main.cpp
//  DBTool
//
//  Created by DuanHongbo on 15/6/10.
//
//

#include <string>
#include <iostream>
#include <fstream>
#include <algorithm>
#include "tclap/CmdLine.h"
#include "DragonBonesHeaders.h"
#include "DBXMLConvert.h"

extern "C" {
#include "pbc.h"
}

using namespace TCLAP;
using namespace std;
using namespace dragonBones;



// Load file "name" into "buf" returning true if successful
// false otherwise.  If "binary" is false data is read
// using ifstream's text mode, otherwise data is read with
// no transcoding.
static bool LoadFile(const char *name, bool binary, std::string *buf) {
    std::ifstream ifs(name, binary ? std::ifstream::binary : std::ifstream::in);
    if (!ifs.is_open()) return false;
    *buf = std::string(std::istreambuf_iterator<char>(ifs),
                       std::istreambuf_iterator<char>());
    return !ifs.bad();
}

// Save data "buf" of length "len" bytes into a file
// "name" returning true if successful, false otherwise.
// If "binary" is false data is written using ifstream's
// text mode, otherwise data is written with no
// transcoding.
static bool SaveFile(const char *name, const char *buf, size_t len,
                     bool binary) {
    std::ofstream ofs(name, binary ? std::ofstream::binary : std::ofstream::out);
    if (!ofs.is_open()) return false;
    ofs.write(buf, len);
    return !ofs.bad();
}


#include "parsers/skeleton_pb.h"
#include "parsers/texture_pb.h"

static pbc_env * init_pbc()
{
    struct pbc_env * env = pbc_new();
    
    struct pbc_slice slice;
    slice.buffer = skeleton_pb;
    slice.len = skeleton_pb_len;
    int r = pbc_register(env, &slice);
    if (r) {
        printf("Error : %s", pbc_error(env));
    }
    
    slice.buffer = texture_pb;
    slice.len = texture_pb_len;
    r = pbc_register(env, &slice);
    if (r) {
        printf("Error : %s", pbc_error(env));
    }
    return  env;
}

int main(int argc, const char * argv[]) {

    struct pbc_env * env = init_pbc();
    
    try {
        
        TCLAP::CmdLine cmd("convert binary file from xml", ' ', "0.1");
        
        TCLAP::ValueArg<std::string> formatArg("f","format","format type (skeleton or texture)",true,"","string");
        cmd.add( formatArg );
        
        TCLAP::ValueArg<std::string> inputArg("i","input","input xml file",true,"","string");
        cmd.add( inputArg );
        
        TCLAP::ValueArg<std::string> outArg("o","output","output path",false,"","string");
        cmd.add( outArg );

        cmd.parse( argc, argv );
        
        
        string skeletonXmlFile ;
        string textureXmlFile ;
        string output = outArg.getValue();
        string format = formatArg.getValue();
        if(format=="skeleton")
        {
            skeletonXmlFile = inputArg.getValue();
        }
        else if(format=="texture")
        {
            textureXmlFile = inputArg.getValue();
        }
        
        std::cout << "skeletonXmlFile : " << skeletonXmlFile << std::endl;
        std::cout << "textureXmlFile : " << textureXmlFile << std::endl;
        std::cout << "output : " << output << std::endl;
        
        string buff;
        if(LoadFile(skeletonXmlFile.c_str(),false,&buff))
        {
            // load skeleton.xml using XML parser.
            XMLDocument document;
            document.Parse(buff.c_str(), buff.size());
            
            struct pbc_wmessage * msg = pbc_wmessage_new(env, "DragonBonesData");
            DBXMLConvert convert;
            convert.toDragonBonesBinary(env, document.RootElement(), msg);
  
            struct pbc_slice slice;
            pbc_wmessage_buffer(msg,&slice);
            
            string outPath = "skeleton.dbb";
            if(output.size()>0)
            {
                outPath = output;
            }
            
            SaveFile(outPath.c_str(),(const char*)slice.buffer,slice.len,true);
            
            pbc_wmessage_delete(msg);
        }
        
        buff.clear();
        if(LoadFile(textureXmlFile.c_str(), false, &buff))
        {
            XMLDocument document;
            document.Parse(buff.c_str(), buff.size());
            
            struct pbc_wmessage * msg = pbc_wmessage_new(env, "TextureAtlasData");
            DBXMLConvert convert;
            convert.toTextureAtlasBinary(env, document.RootElement(), msg);

            struct pbc_slice slice;
            pbc_wmessage_buffer(msg,&slice);
            
            string outPath = "texture.dbb";
            if(output.size()>0)
            {
                outPath = output;
            }
            
            SaveFile(outPath.c_str(),(const char*)slice.buffer,slice.len,true);
            
            pbc_wmessage_delete(msg);
        }
        
    }
    catch (TCLAP::ArgException &e)
    {
        std::cerr << "error: " << e.error() << " for arg " << e.argId() << std::endl;
    }
    
    pbc_delete(env);
    return 0;
}


