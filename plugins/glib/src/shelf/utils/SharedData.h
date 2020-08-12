//
// Created by gen on 6/13/2020.
//

#ifndef ANDROID_SHAREDATA_H
#define ANDROID_SHAREDATA_H

#include <string>
#include <vector>
#include <ctime>
#include <chrono>

namespace gs {
    struct shared {
        static const std::string MAIN_PROJECT_KEY;
        static const std::string HOME_PAGE_LIST;
        static std::string root_path;
        static bool is_debug_mode;
        static std::string debug_path;

        static std::string repo_path(bool ignore_debug = false);

        static const std::vector<uint8_t> public_key;


    };

    std::time_t getTimeStamp();
}


#endif //ANDROID_SHAREDATA_H
