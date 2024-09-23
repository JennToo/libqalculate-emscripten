#include <libqalculate/Calculator.h>
#include <iostream>

int main() {
    auto calc = new Calculator();
    calc->loadGlobalDefinitions();
    calc->loadLocalDefinitions();
    std::cout << calc->calculateAndPrint("1 + 1", 2000) << std::endl;
}
