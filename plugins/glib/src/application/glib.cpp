//
// Created by gen on 8/25/20.
//

#include "glib.h"
#include <core/Ref.h>
#include <core/Callback.h>
#include <core/Array.h>
#include <core/Map.h>
#include "utils/Platform.h"
#include "utils/GitRepository.h"
#include "utils/dart/DartRequest.h"
#include "utils/database/DBMaker.h"
#include "utils/database/SQLite.h"
#include "models/GitLibrary.h"
#include "utils/SharedData.h"
#include "main/Context.h"
#include "main/Project.h"
#include "utils/Bit64.h"
#include "main/DataItem.h"
#include "utils/Request.h"
#include "utils/Encoder.h"
#include "utils/GumboParser.h"
#include "utils/Error.h"
#include "models/KeyValue.h"
#include "utils/ScriptContext.h"
#include "models/CollectionData.h"
#include "main/LibraryContext.h"
#include "main/Settings.h"
#include "utils/dart/DartPlatform.h"
#include "utils/dart/DartBrowser.h"
#include "bit64/bit64.h"
#include "secp256k1.h"
#include <vector>
#include "sha256.h"

using namespace gc;

extern "C" void initGlib() {
    ClassDB::reg<gc::_Map>();
    ClassDB::reg<gc::_Array>();
    ClassDB::reg<gc::_Callback>();
    ClassDB::reg<gc::FileData>();
    ClassDB::reg<gs::GitRepository>();
    ClassDB::reg<gs::DartPlatform>();
    ClassDB::reg<gs::DartRequest>();
    ClassDB::reg<gs::GitAction>();
    ClassDB::reg<gs::GitLibrary>();
    ClassDB::reg<gs::Project>();
    ClassDB::reg<gs::Bit64>();
    ClassDB::reg<gs::Context>();
    ClassDB::reg<gs::Collection>();
    ClassDB::reg<gs::DataItem>();
    ClassDB::reg<gs::Request>();
    ClassDB::reg<gs::Encoder>();
    ClassDB::reg<gs::GumboNode>();
    ClassDB::reg<gs::Error>();
    ClassDB::reg<gs::KeyValue>();
    ClassDB::reg<gs::ScriptContext>();
    ClassDB::reg<gs::CollectionData>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::LibraryContext>();
    ClassDB::reg<gs::SettingItem>();
    ClassDB::reg<gs::Platform>();
    ClassDB::reg<gs::DartBrowser>();
    ClassDB::reg<gs::Browser>();
}

extern "C" int dart_tokenVerify(const char *token, const char *url, const char *prev, const uint8_t *pubKey, int pubKeyLength) {
    sha256_context sha256_ctx;
    sha256_init(&sha256_ctx);
    if (prev) {
        size_t len = strlen(prev);
        std::vector<uint8_t> data;
        data.resize(bit64_decode_size(len));
        size_t d_size = bit64_decode((const uint8_t *)prev, len, data.data());
        sha256_hash(&sha256_ctx, data.data(), d_size);
    }
    size_t url_len = strlen(url);
    sha256_hash(&sha256_ctx, (uint8_t *)url, url_len);
    uint8_t sha256_res[32];
    sha256_done(&sha256_ctx, sha256_res);

    secp256k1_context *secp256k1_ctx = secp256k1_context_create(SECP256K1_CONTEXT_VERIFY);
    secp256k1_pubkey pubkey;
    if (!secp256k1_ec_pubkey_parse(secp256k1_ctx, &pubkey, pubKey, pubKeyLength)) {
        return false;
    }
    uint8_t test[65];
    size_t test_size = 65;
    secp256k1_ec_pubkey_serialize(secp256k1_ctx, test, &test_size, &pubkey, SECP256K1_EC_UNCOMPRESSED);
    secp256k1_ecdsa_signature signature;
    size_t tokenLength = strlen(token);
    size_t dec_size = bit64_decode_size(tokenLength);
    if (dec_size != 64 && dec_size != 65) {
        return false;
    }
    uint8_t *buf = (uint8_t *)malloc(dec_size);
    dec_size = bit64_decode((const uint8_t *)token, tokenLength, buf);
    if (dec_size != 64) {
        free(buf);
        return false;
    }
    secp256k1_ecdsa_signature_parse_compact(secp256k1_ctx, &signature, buf);
    free(buf);
    return secp256k1_ecdsa_verify(secp256k1_ctx, &signature, sha256_res, &pubkey);
}

