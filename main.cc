#include <iostream>

#include <read_file.hpp>

int main() {
    std::vector<char> data = garnish::read_file("../Sample Scenes/version1.scdsk");

    std::string sceneFile{ data.begin(), data.end() };

    std::cout << "File Content:\n" << sceneFile << std::endl;
}
