#pragma once

#include <cstddef>
#include <filesystem>
#include <string>

namespace sporebridge {

enum class Edition {
  unknown,
  base_game,
  galactic_adventures,
};

struct InstallationReport {
  bool valid = false;
  Edition edition = Edition::unknown;
  std::filesystem::path root;
  std::filesystem::path executable;
  std::filesystem::path data_directory;
  std::size_t package_count = 0;
  std::size_t scanned_entries = 0;
  std::string message;
};

InstallationReport validate_installation(
    const std::filesystem::path& selected_root);

std::string edition_name(Edition edition);

}  // namespace sporebridge

