pub type SidebarFeature {
  SidebarLink(text: String, link: String, new_tab: Bool, current_path: String)
  SidebarDropdown(text: String, sub: List(SidebarFeature))
  SidebarDivider
}

pub fn get_sidebar_features(current_path: String) {
  [
    SidebarLink("Giolt", "https://giolt.com", False, current_path:),
    SidebarLink("GitHub", "https://github.com/withgiolt", True, current_path:),
    SidebarDivider,
    SidebarDropdown("Hello, world!", [
      SidebarLink("Home", "/", False, current_path:),
      SidebarLink("Get started", "/get-started", False, current_path:),
      SidebarLink(
        "Giolt SDK Configuration",
        "/configuration",
        False,
        current_path:,
      ),
    ]),
    SidebarDropdown("GlowVM - EXPERIMENTAL", [
      SidebarLink("About GlowVM", "/glowvm/about", False, current_path:),
    ]),
  ]
}
