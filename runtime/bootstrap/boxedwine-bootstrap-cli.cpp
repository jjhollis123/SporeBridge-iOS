#include <exception>
#include <iostream>
#include <vector>

int boxedmain(int argc, const char** argv);

int main(int argc, char** argv) {
  std::vector<const char*> arguments(argv, argv + argc);
  try {
    return boxedmain(argc, arguments.data());
  } catch (const std::exception& error) {
    std::cerr << "Boxedwine bootstrap failed: " << error.what() << '\n';
    return 1;
  }
}
