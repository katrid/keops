<?xml version="1.0" encoding="utf-8"?>
<data>
  <action id="action-sys-modules" model="base.module"/>
  <action id="action-sys-settings" model="base.config"/>
  <action id="action-sys-companies" model="base.company"/>
  <action id="action-sys-auth-users" model="base.user"/>
  <action id="action-sys-auth-groups" model="base.group"/>
  <action id="action-sys-ui-menu" model="base.menu"/>
  <action id="action-sys-ui-views" model="base.view"/>
  <action id="action-sys-ui-reports" model="base.report"/>
  <action id="action-sys-ui-view-actions" models="base.viewaction"/>
  <action id="action-sys-ui-report-actions" models="base.reportaction"/>
  <action id="action-sys-models" models="contenttypes.contenttype"/>
  <action id="action-sys-fields" models="base.field"/>
  <menuitem id="menu-settings" name="${_('Settings')}" sequence="9000">
    <menuitem id="menu-sys-adm" name="${_('Administration')}" sequence="100">
      <menuitem id="menu-sys-modules" name="${_('Addons')}" sequence="100" action="action-sys-modules"/>
      <menuitem id="menu-sys-settings" name="${_('Settings')}" sequence="110" action="action-sys-settings"/>
    </menuitem>
    <menuitem id="menu-sys-companies" name="${_('Companies')}" sequence="110">
      <menuitem id="menu-sys-companies-companies" name="${_('Companies')}" sequence="100" action="action-sys-companies"/>
    </menuitem>
    <menuitem id="menu-sys" name="${_('System')}" sequence="120">
      <menuitem id="menu-sys-auth" name="${_('Authentication')}" sequence="100">
        <menuitem id="menu-sys-auth-users" name="${_('Users')}" sequence="100" model="base.user" action="action-sys-auth-users"/>
        <menuitem id="menu-sys-auth-groups" name="${_('Groups')}" sequence="110" model="base.group" acton="action-sys-auth-groups"/>
      </menuitem>
      <menuitem id="menu-sys-custom" name="${_('Customization')}" sequence="110">
        <menuitem id="menu-sys-ui" name="${_('User Interface')}" sequence="100">
          <menuitem id="menu-sys-ui-menu" name="${_('Menu')}" sequence="100" action="action-sys-ui-menu"/>
          <menuitem id="menu-sys-ui-views" name="${_('Views')}" sequence="110" action="action-sys-ui-views"/>
          <menuitem id="menu-sys-ui-reports" name="${_('Reports')}" sequence="120" action="action-sys-ui-reports"/>
          <menuitem id="menu-sys-ui-actions" name="${_('Actions')}" sequence="130" action="action-sys-ui-actions">
            <menuitem id="menu-sys-ui-view-actions" name="${_('View actions')}" sequence="100" action="action-sys-ui-view-actions"/>
            <menuitem id="menu-sys-ui-report-actions" name="${_('Report actions')}" sequence="110" model="action-sys-ui-report-actions"/>
          </menuitem>
        </menuitem>
        <menuitem id="menu-sys-datadict" name="${_('Data Dictionary')}" sequence="140">
          <menuitem id="menu-sys-models" name="${_('Models')}" sequence="100" model="contenttypes.contenttype" action="action-sys-models"/>
          <menuitem id="menu-sys-fields" name="${_('Fields')}" sequence="110" model="base.field" action="action-sys-fields"/>
        </menuitem>
      </menuitem>
    </menuitem>
  </menuitem>
</data>