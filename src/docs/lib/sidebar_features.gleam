pub type SidebarFeature {
  SidebarLink(text: String, link: String, new_tab: Bool, current_path: String)
  SidebarDropdown(text: String, sub: List(SidebarFeature))
  SidebarDivider
}

pub fn get_sidebar_features(current_path: String) {
  [
    SidebarLink("Giolt", "https://giolt.com", False, current_path:),
    SidebarLink("GitHub", "https://github.com/withgiolt", True, current_path:),
    SidebarLink(
      "Issues",
      "https://github.com/withgiolt/issues",
      True,
      current_path:,
    ),
    SidebarDivider,
    SidebarDropdown("Hello, world!", [
      SidebarLink("Home", "/", False, current_path:),
      SidebarLink("Get started", "/get-started", False, current_path:),
      SidebarLink("CLI", "/cli", False, current_path:),
      SidebarLink("Deploy from CI", "/ci", False, current_path:),
      SidebarLink("Limits", "/limits", False, current_path:),
      SidebarLink("For coding agents", "/agents", False, current_path:),
    ]),
    SidebarDropdown("API", [
      SidebarLink("Overview", "/api/about", False, current_path:),
      SidebarLink("Projects", "/api/projects", False, current_path:),
      SidebarLink("Deploy", "/api/deploy", False, current_path:),
    ]),
    SidebarDropdown("afterglow - EXPERIMENTAL", [
      SidebarLink("About afterglow", "/afterglow/about", False, current_path:),
      SidebarLink("How to use", "/afterglow/how-to-use", False, current_path:),
    ]),
  ]
}
