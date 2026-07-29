#include "spore_install_validator.h"

#include <algorithm>
#include <cctype>
#include <optional>
#include <system_error>

namespace sporebridge {
namespace {

constexpr std::size_t kMaximumScannedEntries = 250000;

std::string lowercase_ascii(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](const unsigned char character) {
                   return static_cast<char>(std::tolower(character));
                 });
  return value;
}

bool equals_case_insensitive(const std::string& lhs, const std::string& rhs) {
  return lowercase_ascii(lhs) == lowercase_ascii(rhs);
}

bool starts_with_case_insensitive(const std::string& value,
                                  const std::string& prefix) {
  const std::string lowered_value = lowercase_ascii(value);
  const std::string lowered_prefix = lowercase_ascii(prefix);
  return lowered_value.rfind(lowered_prefix, 0) == 0;
}

bool is_package_file(const std::filesystem::path& path) {
  return equals_case_insensitive(path.extension().string(), ".package");
}

bool parent_path_contains(const std::filesystem::path& path,
                          const std::string& wanted_component) {
  for (const auto& component : path) {
    if (equals_case_insensitive(component.string(), wanted_component)) {
      return true;
    }
  }
  return false;
}

struct Candidate {
  std::filesystem::path executable;
  Edition edition = Edition::unknown;
};

int candidate_priority(const Candidate& candidate) {
  switch (candidate.edition) {
    case Edition::galactic_adventures:
      return 3;
    case Edition::base_game:
      return 2;
    case Edition::unknown:
      return 1;
  }
  return 0;
}

}  // namespace

InstallationReport validate_installation(
    const std::filesystem::path& selected_root) {
  InstallationReport report;
  report.root = selected_root;

  std::error_code error;
  if (!std::filesystem::is_directory(selected_root, error) || error) {
    report.message = "Choose the top-level Spore installation folder.";
    return report;
  }

  std::optional<Candidate> best_executable;
  std::optional<std::filesystem::path> best_data_directory;
  std::size_t best_package_count = 0;

  const auto options =
      std::filesystem::directory_options::skip_permission_denied;
  std::filesystem::recursive_directory_iterator iterator(selected_root, options,
                                                          error);
  const std::filesystem::recursive_directory_iterator end;

  while (!error && iterator != end &&
         report.scanned_entries < kMaximumScannedEntries) {
    const std::filesystem::directory_entry entry = *iterator;
    ++report.scanned_entries;

    const std::string filename = entry.path().filename().string();
    if (entry.is_regular_file(error) &&
        equals_case_insensitive(filename, "SporeApp.exe")) {
      Candidate candidate;
      candidate.executable = entry.path();
      if (parent_path_contains(entry.path(), "SporebinEP1")) {
        candidate.edition = Edition::galactic_adventures;
      } else if (parent_path_contains(entry.path(), "SporeBin")) {
        candidate.edition = Edition::base_game;
      }

      if (!best_executable ||
          candidate_priority(candidate) >
              candidate_priority(*best_executable)) {
        best_executable = candidate;
      }
    }

    if (entry.is_directory(error) &&
        starts_with_case_insensitive(filename, "Data")) {
      std::size_t package_count = 0;
      std::error_code package_error;
      std::filesystem::recursive_directory_iterator package_iterator(
          entry.path(), options, package_error);
      while (!package_error && package_iterator != end &&
             report.scanned_entries < kMaximumScannedEntries) {
        const std::filesystem::directory_entry package_entry =
            *package_iterator;
        ++report.scanned_entries;
        if (package_entry.is_regular_file(package_error) &&
            is_package_file(package_entry.path())) {
          ++package_count;
        }
        package_iterator.increment(package_error);
      }

      if (package_count > best_package_count) {
        best_package_count = package_count;
        best_data_directory = entry.path();
      }

      iterator.disable_recursion_pending();
    }

    iterator.increment(error);
  }

  if (report.scanned_entries >= kMaximumScannedEntries) {
    report.message =
        "The selected folder is too broad. Choose the Spore installation "
        "folder itself.";
    return report;
  }

  if (!best_executable) {
    report.message =
        "SporeApp.exe was not found. Choose the folder containing SporeBin "
        "or SporebinEP1.";
    return report;
  }

  report.executable = best_executable->executable;
  report.edition = best_executable->edition;

  if (!best_data_directory || best_package_count == 0) {
    report.message =
        "The executable was found, but no Spore .package data was found. "
        "Choose the complete installation folder, not SporeBin by itself.";
    return report;
  }

  report.data_directory = *best_data_directory;
  report.package_count = best_package_count;
  report.valid = true;
  report.message = "A compatible " + edition_name(report.edition) +
                   " installation was found.";
  return report;
}

std::string edition_name(const Edition edition) {
  switch (edition) {
    case Edition::base_game:
      return "Spore base-game";
    case Edition::galactic_adventures:
      return "Spore Galactic Adventures";
    case Edition::unknown:
      return "Spore";
  }
  return "Spore";
}

}  // namespace sporebridge

