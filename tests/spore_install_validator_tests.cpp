#include "spore_install_validator.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

namespace fs = std::filesystem;

class TemporaryDirectory {
 public:
  TemporaryDirectory() {
    const fs::path base = fs::temp_directory_path();
    for (int attempt = 0; attempt < 100; ++attempt) {
      path_ = base / ("sporebridge-test-" +
                      std::to_string(std::rand()) + "-" +
                      std::to_string(attempt));
      std::error_code error;
      if (fs::create_directory(path_, error)) {
        return;
      }
    }
    throw std::runtime_error("Could not create a test directory");
  }

  ~TemporaryDirectory() {
    std::error_code error;
    fs::remove_all(path_, error);
  }

  const fs::path& path() const { return path_; }

 private:
  fs::path path_;
};

void touch(const fs::path& path) {
  fs::create_directories(path.parent_path());
  std::ofstream file(path, std::ios::binary);
  file << "test";
}

void require(bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

void test_base_game_layout() {
  TemporaryDirectory directory;
  touch(directory.path() / "SporeBin" / "SporeApp.exe");
  touch(directory.path() / "Data" / "Spore_Game.package");

  const auto report =
      sporebridge::validate_installation(directory.path());
  require(report.valid, report.message);
  require(report.edition == sporebridge::Edition::base_game,
          "Expected base-game detection");
  require(report.package_count == 1, "Expected one package");
}

void test_galactic_adventures_is_preferred() {
  TemporaryDirectory directory;
  touch(directory.path() / "SporeBin" / "SporeApp.exe");
  touch(directory.path() / "SporebinEP1" / "SporeApp.exe");
  touch(directory.path() / "DataEP1" / "EP1_Content.package");

  const auto report =
      sporebridge::validate_installation(directory.path());
  require(report.valid, report.message);
  require(report.edition == sporebridge::Edition::galactic_adventures,
          "Expected Galactic Adventures detection");
  require(report.executable.parent_path().filename() == "SporebinEP1",
          "Expected the expansion executable");
}

void test_case_insensitive_layout() {
  TemporaryDirectory directory;
  touch(directory.path() / "SPOREBIN" / "SPOREAPP.EXE");
  touch(directory.path() / "data" / "content.PACKAGE");

  const auto report =
      sporebridge::validate_installation(directory.path());
  require(report.valid, report.message);
  require(report.edition == sporebridge::Edition::base_game,
          "Expected case-insensitive base-game detection");
}

void test_missing_executable_fails() {
  TemporaryDirectory directory;
  touch(directory.path() / "Data" / "Spore_Game.package");

  const auto report =
      sporebridge::validate_installation(directory.path());
  require(!report.valid, "Missing executable should fail");
  require(report.message.find("SporeApp.exe") != std::string::npos,
          "Failure should explain the missing executable");
}

void test_selecting_sporebin_alone_fails() {
  TemporaryDirectory directory;
  touch(directory.path() / "SporeBin" / "SporeApp.exe");

  const auto report = sporebridge::validate_installation(
      directory.path() / "SporeBin");
  require(!report.valid, "Executable-only folder should fail");
  require(report.message.find(".package") != std::string::npos,
          "Failure should explain the missing packages");
}

}  // namespace

int main() {
  try {
    test_base_game_layout();
    test_galactic_adventures_is_preferred();
    test_case_insensitive_layout();
    test_missing_executable_fails();
    test_selecting_sporebin_alone_fails();
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
  }

  std::cout << "All Spore installation validator tests passed.\n";
  return 0;
}

