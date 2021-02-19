#requires -version 3
<#
.SYNOPSIS
Download and Install several Software with the Evergreen module from Aaron Parker, Bronson Magnan and Trond Eric Haarvarstein. 
.DESCRIPTION
To update or download a software package just switch from 0 to 1 in the section "Select software" (With parameter -list) or select your Software out of the GUI.
A new folder for every single package will be created, together with a version file, a download date file and a log file. If a new version is available
the script checks the version number and will update the package.
.NOTES
  Version:          0.9
  Author:           Manuel Winkel <www.deyda.net>
  Creation Date:    2021-01-29
  Purpose/Change:
  2021-01-29        Initial Version
  2021-01-30        Error solved: No installation without parameters / Add WinSCP Install
  2021-01-31        Error solved: Installation Workspace App -> Wrong Variable / Error solved: Detection acute version 7-Zip -> Limitation of the results
  2021-02-01        Add Gui Mode as Standard
  2021-02-02        Add Install OpenJDK / Add Install VMWare Tools / Add Install Oracle Java 8 / Add Install Adobe Reader DC
  2021-02-03        Addition of verbose comments. Chrome and Edge customization regarding disabling services and scheduled tasks.
  2021-02-04        Correction OracleJava8 detection / Add Environment Variable $env:evergreen for script path
  2021-02-12        Add Download Citrix Hypervisor Tools, Greenshot, Firefox, Foxit Reader & Filezilla / Correction Citrix Workspace Download & Install Folder / Adding Citrix Receiver Cleanup Utility
  2021-02-14        Change Adobe Acrobat DC Downloader
  2021-02-15        Change MS Teams Downloader / Correction GUI Select All / Add Download MS Apps 365 & Office 2019 Install Files / Add Uninstall and Install MS Apps 365 & Office 2019
  2021-02-18        Correction Code regarding location of scripts at MS365Apps and MSOffice2019. Removing Download Time Files.
  2021-02-19        Implementation of new GUI / Choice of architecture option in 7-Zip / Choice of language option in Adobe Reader DC

.PARAMETER download

Only download the software packages.

.PARAMETER install

Only install the software packages.

.PARAMETER list

Don't start the GUI to select the Software Packages and use the hardcoded list in the script.

.EXAMPLE

& '.\Evergreen.ps1 -download

Downlod the selected Software.

.EXAMPLE

& '.\Evergreen.ps1

Download and install the selected Software.

.EXAMPLE

& '.\Evergreen.ps1 -list

Download and install the selected Software out of the script.
#>

[CmdletBinding()]


Param (
    
        [Parameter(
            HelpMessage='Only Download Software?',
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$download,

        [Parameter(
            HelpMessage='Only Install Software?',
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$install,
    
        [Parameter(
            HelpMessage='Start the Gui to select the Software',
            ValuefromPipelineByPropertyName = $true
        )]
        [switch]$list
    
)

# Do you run the script as admin?
# ========================================================================================================================================
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Script Version
# ========================================================================================================================================
$eVersion = "0.9"
Write-Verbose "Evergreen Download and Install Script by Manuel Winkel (www.deyda.net) - Version $eVersion" -Verbose
Write-Output ""

if ($myWindowsPrincipal.IsInRole($adminRole)) {
    # OK, runs as admin
    Write-Verbose "OK, script is running with Admin rights" -Verbose
    Write-Output ""
}
else {
    # Script doesn't run as admin, stop!
    Write-Verbose "Error! Script is NOT running with Admin rights!" -Verbose
    BREAK
}

# FUNCTION GUI
# ========================================================================================================================================

function gui_mode{

#XAML Code
$inputXML = @"
<Window x:Class="GUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:GUI"
        mc:Ignorable="d"
        Title="Evergreen - Update your Software, the lazy way" Height="470" Width="840">
    <Grid x:Name="Evergreen_GUI">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="13*"/>
            <ColumnDefinition Width="234*"/>
            <ColumnDefinition Width="586*"/>
        </Grid.ColumnDefinitions>
        <Image x:Name="Image_Logo" Height="100" Margin="467,0,19,0" VerticalAlignment="Top" Width="100" Source="https://www.deyda.net/wp-content/uploads/2020/03/Logo_DEYDA_no_cta.png" Grid.Column="2" ToolTip="www.deyda.net"/>
        <Button x:Name="Button_Start" Content="Start" HorizontalAlignment="Left" Margin="258,375,0,0" VerticalAlignment="Top" Width="75" Grid.Column="2"/>
        <Button x:Name="Button_Cancel" Content="Cancel" HorizontalAlignment="Left" Margin="353,375,0,0" VerticalAlignment="Top" Width="75" Grid.Column="2"/>
        <Label x:Name="Label_SelectMode" Content="Select Mode" HorizontalAlignment="Left" Margin="15.5,10,0,0" VerticalAlignment="Top" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_Download" Content="Download" HorizontalAlignment="Left" Margin="15.5,41,0,0" VerticalAlignment="Top" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_Install" Content="Install" HorizontalAlignment="Left" Margin="102.5,41,0,0" VerticalAlignment="Top" Grid.Column="1"/>
        <Label x:Name="Label_SelectLanguage" Content="Select Language" HorizontalAlignment="Left" Margin="73,10,0,0" VerticalAlignment="Top" Grid.Column="2"/>
        <ComboBox x:Name="Box_Language" HorizontalAlignment="Left" Margin="86,37,0,0" VerticalAlignment="Top" SelectedIndex="2" Grid.Column="2" ToolTip="If this is selectable at download!">
            <ListBoxItem Content="Danish"/>
            <ListBoxItem Content="Dutch"/>
            <ListBoxItem Content="English"/>
            <ListBoxItem Content="Finnish"/>
            <ListBoxItem Content="French"/>
            <ListBoxItem Content="German"/>
            <ListBoxItem Content="Italian"/>
            <ListBoxItem Content="Japanese"/>
            <ListBoxItem Content="Korean"/>
            <ListBoxItem Content="Norwegian"/>
            <ListBoxItem Content="Polish"/>
            <ListBoxItem Content="Portuguese"/>
            <ListBoxItem Content="Russian"/>
            <ListBoxItem Content="Spanish"/>
            <ListBoxItem Content="Swedish"/>
        </ComboBox>
        <Label x:Name="Label_SelectArchitecture" Content="Select Architecture" HorizontalAlignment="Left" Margin="241,10,0,0" VerticalAlignment="Top" Grid.Column="2"/>
        <ComboBox x:Name="Box_Architecture" HorizontalAlignment="Left" Margin="275,37,0,0" VerticalAlignment="Top" SelectedIndex="0" RenderTransformOrigin="0.864,0.591" Grid.Column="2" ToolTip="If this is selectable at download!">
            <ListBoxItem Content="x64"/>
            <ListBoxItem Content="x86"/>
        </ComboBox>
        <Label x:Name="Label_Explanation" Content="When software download can be filtered on language or architecture." HorizontalAlignment="Left" Margin="58,59,0,0" VerticalAlignment="Top" FontSize="10" Grid.Column="2"/>
        <Label x:Name="Label_Software" Content="Select Software" HorizontalAlignment="Left" Margin="15.5,70,0,0" VerticalAlignment="Top" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_7Zip" Content="7 Zip" HorizontalAlignment="Left" Margin="15.5,101,0,0" VerticalAlignment="Top" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_AdobeProDC" Content="Adobe Pro DC" HorizontalAlignment="Left" Margin="15.5,121,0,0" VerticalAlignment="Top" Grid.Column="1" ToolTip="Update Only!"/>
        <CheckBox x:Name="Checkbox_AdobeReaderDC" Content="Adobe Reader DC" HorizontalAlignment="Left" Margin="15.5,141,0,0" VerticalAlignment="Top" Grid.Column="1" />
        <CheckBox x:Name="Checkbox_BISF" Content="BIS-F" HorizontalAlignment="Left" Margin="15.5,161,0,0" VerticalAlignment="Top" Grid.Column="1" />
        <CheckBox x:Name="Checkbox_CitrixHypervisorTools" Content="Citrix Hypervisor Tools" HorizontalAlignment="Left" Margin="15.5,181,0,0" VerticalAlignment="Top" Grid.Column="1" />
        <CheckBox x:Name="Checkbox_CitrixWorkspaceApp" Content="Citrix Workspace App" HorizontalAlignment="Left" Margin="15.5,201,0,0" VerticalAlignment="Top" Grid.Column="1" />
        <ComboBox x:Name="Box_CitrixWorksapceApp" HorizontalAlignment="Left" Margin="173,198,0,0" VerticalAlignment="Top" SelectedIndex="1" Grid.ColumnSpan="2" Grid.Column="1">
            <ListBoxItem Content="Current Release"/>
            <ListBoxItem Content="Long Term Service Release"/>
        </ComboBox>
        <CheckBox x:Name="Checkbox_Filezilla" Content="Filezilla" HorizontalAlignment="Left" Margin="15.5,221,0,0" VerticalAlignment="Top" Grid.Column="1" />
        <CheckBox x:Name="Checkbox_FoxitReader" Content="Foxit Reader" HorizontalAlignment="Left" Margin="15.5,241,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1" ToolTip="No sileent installation"/>
        <CheckBox x:Name="Checkbox_GoogleChrome" Content="Google Chrome" HorizontalAlignment="Left" Margin="15.5,261,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_Greenshot" Content="Greenshot" HorizontalAlignment="Left" Margin="15.5,281,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_KeePass" Content="KeePass" HorizontalAlignment="Left" Margin="16.5,301,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_mRemoteNG" Content="mRemoteNG" HorizontalAlignment="Left" Margin="16.5,321,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1"/>
        <CheckBox x:Name="Checkbox_MSEdge" Content="Microsoft Edge" HorizontalAlignment="Left" Margin="243,101,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_MSFSlogix" Content="Microsoft FSLogix" HorizontalAlignment="Left" Margin="243,121,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_MSOffice2019" Content="Microsoft Office 2019" HorizontalAlignment="Left" Margin="243,141,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_MSOneDrive" Content="Microsoft OneDrive" HorizontalAlignment="Left" Margin="243,161,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2" ToolTip="Machine Based Install"/>
        <ComboBox x:Name="Box_MSOneDrive" HorizontalAlignment="Left" Margin="407,154,0,0" VerticalAlignment="Top" SelectedIndex="2" Grid.Column="2" ToolTip="Machine Based Install">
            <ListBoxItem Content="Insider Ring"/>
            <ListBoxItem Content="Production Ring"/>
            <ListBoxItem Content="Enterprise Ring"/>
        </ComboBox>
        <CheckBox x:Name="Checkbox_MSTeams" Content="Microsoft Teams" HorizontalAlignment="Left" Margin="243,181,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2" ToolTip="Machine Based Install"/>
        <ComboBox x:Name="Box_MSTeams" HorizontalAlignment="Left" Margin="407,176,0,0" VerticalAlignment="Top" SelectedIndex="1" Grid.Column="2" ToolTip="Machine Based Install">
            <ListBoxItem Content="Preview Ring"/>
            <ListBoxItem Content="General Ring"/>
        </ComboBox>
        <CheckBox x:Name="Checkbox_Firefox" Content="Mozilla Firefox" HorizontalAlignment="Left" Margin="243,201,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <ComboBox x:Name="Box_Firefox" HorizontalAlignment="Left" Margin="407,198,0,0" VerticalAlignment="Top" SelectedIndex="0" Grid.Column="2">
            <ListBoxItem Content="Current"/>
            <ListBoxItem Content="ESR"/>
        </ComboBox>
        <CheckBox x:Name="Checkbox_NotepadPlusPlus" Content="Notepad ++" HorizontalAlignment="Left" Margin="243,221,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_OpenJDK" Content="Open JDK" HorizontalAlignment="Left" Margin="243,241,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_OracleJava8" Content="Oracle Java 8" HorizontalAlignment="Left" Margin="243,261,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_TreeSize" Content="TreeSize" HorizontalAlignment="Left" Margin="243,281,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <ComboBox x:Name="Box_TreeSize" HorizontalAlignment="Left" Margin="407,277,0,0" VerticalAlignment="Top" SelectedIndex="0" Grid.Column="2">
            <ListBoxItem Content="Free"/>
            <ListBoxItem Content="Professional"/>
        </ComboBox>
        <CheckBox x:Name="Checkbox_VLCPlayer" Content="VLC Player" HorizontalAlignment="Left" Margin="243,301,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_VMWareTools" Content="VMWare Tools" HorizontalAlignment="Left" Margin="243,321,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_WinSCP" Content="WinSCP" HorizontalAlignment="Left" Margin="243,341,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_SelectAll" Content="Select All" HorizontalAlignment="Left" Margin="9,386,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="2"/>
        <Label x:Name="Label_author" Content="Manuel Winkel / @deyda84 / www.deyda.net / 2021" HorizontalAlignment="Left" Margin="309,404,0,0" VerticalAlignment="Top" FontSize="10" Grid.Column="2"/>
        <CheckBox x:Name="Checkbox_MS365Apps" Content="Microsoft 365 Apps" HorizontalAlignment="Left" Margin="17,341,0,0" VerticalAlignment="Top"  RenderTransformOrigin="0.517,1.133" Grid.Column="1"/>
        <ComboBox x:Name="Box_MS365Apps" HorizontalAlignment="Left" Margin="173,337,0,0" VerticalAlignment="Top" SelectedIndex="4" Grid.Column="1" Grid.ColumnSpan="2">
            <ListBoxItem Content="Current (Preview)"/>
            <ListBoxItem Content="Current"/>
            <ListBoxItem Content="Monthly Enterprise"/>
            <ListBoxItem Content="Semi-Annual Enterprise (Preview)"/>
            <ListBoxItem Content="Semi-Annual Enterprise"/>
        </ComboBox>
    </Grid>
</Window>
"@

    #Correction XAML
    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $inputXML

    #Read XAML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    try{
        $Form=[Windows.Markup.XamlReader]::Load( $reader )
    }
    catch{
        Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
        throw
    }

    # Load XAML Objects In PowerShell  
    $xaml.SelectNodes("//*[@Name]") | %{"trying item $($_.Name)";
        try {Set-Variable –Name "WPF$($_.Name)" –Value $Form.FindName($_.Name) –ErrorAction Stop}
        catch{throw}
    } | out-null
 
    Function Get-FormVariables{
    if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" –ForegroundColor Yellow;$global:ReadmeDisplay=$true}
        write-host "Found the following interactable elements from our form" –ForegroundColor Cyan
        get-variable WPF*
    }

    Get-FormVariables | out-null

    # Set Variable
    $Script:install = $true
    $Script:download = $true

    # Event Handler
    # Checkbox SelectAll
    $WPFCheckbox_SelectAll.Add_Checked({
        $WPFCheckbox_7Zip.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_AdobeProDC.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_AdobeReaderDC.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_BISF.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_CitrixHypervisorTools.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_CitrixWorkspaceApp.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Filezilla.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Firefox.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_FoxitReader.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSFSLogix.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_GoogleChrome.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Greenshot.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_KeePass.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_mRemoteNG.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MS365Apps.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSEdge.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSOffice2019.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSOneDrive.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSTeams.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_NotePadPlusPlus.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_OpenJDK.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_OracleJava8.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_TreeSize.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_VLCPlayer.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_VMWareTools.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_WinSCP.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        
    })
    $WPFCheckbox_SelectAll.Add_Unchecked({
        $WPFCheckbox_7Zip.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_AdobeProDC.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_AdobeReaderDC.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_BISF.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_CitrixHypervisorTools.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_CitrixWorkspaceApp.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Filezilla.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Firefox.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_FoxitReader.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSFSLogix.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_GoogleChrome.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_Greenshot.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_KeePass.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_mRemoteNG.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MS365Apps.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSEdge.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSOffice2019.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSOneDrive.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_MSTeams.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_NotePadPlusPlus.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_OpenJDK.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_OracleJava8.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_TreeSize.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_VLCPlayer.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_VMWareTools.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        $WPFCheckbox_WinSCP.IsChecked = $WPFCheckbox_SelectAll.IsChecked
        
    })
    # Button Start                                                                    
    $WPFButton_Start.Add_Click({
        if ($WPFCheckbox_Download.IsChecked -eq $True) {$Script:install = $false}
        else {$Script:install = $true}
        if ($WPFCheckbox_Install.IsChecked -eq $True) {$Script:download = $false}
        else {$Script:download = $true}
        if ($WPFCheckbox_7Zip.IsChecked -eq $true) {$Script:7ZIP = 1}
        else {$Script:7ZIP = 0}
        if ($WPFCheckbox_AdobeProDC.IsChecked -eq $true) {$Script:AdobeProDC = 1}
        else {$Script:AdobeProDC = 0}
        if ($WPFCheckbox_AdobeReaderDC.IsChecked -eq $true) {$Script:AdobeReaderDC = 1}
        else {$Script:AdobeReaderDC = 0}
        if ($WPFCheckbox_BISF.IsChecked -eq $true) {$Script:BISF = 1}
        else {$Script:BISF = 0}
        if ($WPFCheckbox_CitrixHypervisorTools.IsChecked -eq $true) {$Script:Citrix_Hypervisor_Tools = 1}
        else {$Script:Citrix_Hypervisor_Tools = 0}
        if ($WPFCheckbox_CitrixWorkspaceApp.IsChecked -eq $true) {$Script:Citrix_WorkspaceApp = 1}
        else {$Script:Citrix_WorkspaceApp = 0}
        if ($Citrix_WorkspaceApp_LTSRBox.checked -eq $true) {$Script:Citrix_WorkspaceApp_LTSR = 1}
        else {$Script:Citrix_WorkspaceApp_LTSR = 0}
        if ($WPFCheckbox_Filezilla.IsChecked -eq $true) {$Script:Filezilla = 1}
        else {$Script:Filezilla = 0}
        if ($WPFCheckbox_Firefox.IsChecked -eq $true) {$Script:Firefox = 1}
        else {$Script:Firefox = 0}
        if ($WPFCheckbox_MSFSLogix.IsChecked -eq $true) {$Script:FSLogix = 1}
        else {$Script:FSLogix = 0}
        if ($WPFCheckbox_Foxit_Reader.Ischecked -eq $true) {$Script:Foxit_Reader = 1}
        else {$Script:Foxit_Reader = 0}
        if ($WPFCheckbox_GoogleChrome.ischecked -eq $true) {$Script:GoogleChrome = 1}
        else {$Script:GoogleChrome = 0}
        if ($WPFCheckbox_Greenshot.ischecked -eq $true) {$Script:Greenshot = 1}
        else {$Script:Greenshot = 0}
        if ($WPFCheckbox_KeePass.ischecked -eq $true) {$Script:KeePass = 1}
        else {$Script:KeePass = 0}
        if ($WPFCheckbox_mRemoteNG.ischecked -eq $true) {$Script:mRemoteNG = 1}
        else {$Script:mRemoteNG = 0}
        if ($WPFCheckbox_MS365Apps.ischecked -eq $true) {$Script:MS365Apps = 1}
        else {$Script:MS365Apps = 0}
        if ($WPFCheckbox_MSEdge.ischecked -eq $true) {$Script:MSEdge = 1}
        else {$Script:MSEdge = 0}
        if ($WPFCheckbox_MSOffice2019.ischecked -eq $true) {$Script:MSOffice2019 = 1}
        else {$Script:MSOffice2019 = 0}
        if ($WPFCheckbox_MSOneDrive.ischecked -eq $true) {$Script:MSOneDrive = 1}
        else {$Script:MSOneDrive = 0}
        if ($WPFCheckbox_MSTeams.ischecked -eq $true) {$Script:MSTeams = 1}
        else {$Script:MSTeams = 0}
        if ($WPFCheckbox_NotePadPlusPlus.ischecked -eq $true) {$Script:NotePadPlusPlus = 1}
        else {$Script:NotePadPlusPlus = 0}
        if ($WPFCheckbox_OpenJDK.ischecked -eq $true) {$Script:OpenJDK = 1}
        else {$Script:OpenJDK = 0}
        if ($WPFCheckbox_OracleJava8.ischecked -eq $true) {$Script:OracleJava8 = 1}
        else {$Script:OracleJava8 = 0}
        if ($WPFCheckbox_TreeSize.ischecked -eq $true) {$Script:TreeSizeFree = 1}
        else {$Script:TreeSizeFree = 0}
        if ($WPFCheckbox_VLCPlayer.ischecked -eq $true) {$Script:VLCPlayer = 1}
        else {$Script:VLCPlayer = 0}
        if ($WPFCheckbox_VMWareTools.ischecked -eq $true) {$Script:VMWareTools = 1}
        else {$Script:VMWareTools = 0}
        if ($WPFCheckbox_WinSCP.ischecked -eq $true) {$Script:WinSCP = 1}
        else {$Script:WinSCP = 0}
        $Script:Language = $WPFBox_Language.SelectedIndex
        $Script:Architecture = $WPFBox_Architecture.SelectedIndex
        $Script:FirefoxChannel = $WPFBox_Firefox.SelectedIndex
        $Script:CitrixWorkspaceAppRelease = $WPFBox_CitrixWorkspaceApp.SelectedIndex
        $Script:MS365AppsChannel = $WPFBox_MS365Apps.SelectedIndex
        $Script:MSOneDriveRing = $WPFBox_MSOneDrive.SelectedIndex
        $Script:MSTeamsRing = $WPFBox_MSTeams.SelectedIndex
        $Script:TreeSizeType = $WPFBox_TreeSize.SelectedIndex
        Write-Verbose "GUI MODE" -Verbose
        $Form.Close()
    })

    # Button Cancel                                                                    
    $WPFButton_Cancel.Add_Click({
        $Script:install = $true
        $Script:download = $true
        Write-Verbose "GUI MODE Canceled - Nothing happens" -Verbose
        $Form.Close()
    })

    # Shows the form
    $Form.ShowDialog() | out-null
}

#===========================================================================

Write-Verbose "Setting Variables" -Verbose
Write-Output ""

# Define and Reset Variables
$Date = $Date = Get-Date -UFormat "%m.%d.%Y"
$Script:install = $install
$Script:download = $download
Write-Verbose "Setting Environment Variable Evergreen" -Verbose
Write-Output ""
$Env:evergreen = $PSScriptRoot
if ($list -eq $True) {
    # Select Language (If this is selectable at download)
    # 0 = Danish
    # 1 = Dutch
    # 2 = English
    # 3 = Finnish
    # 4 = French
    # 5 = German
    # 6 = Italian
    # 7 = Japanese
    # 8 = Korean
    # 9 = Norwegian
    # 10 = Polish
    # 11 = Portuguese
    # 12 = Russian
    # 13 = Spanish
    # 14 = Swedish
    $Language = 2

    # Select Architecture (If this is selectable at download)
    # 0 = x64
    # 1 = x86
    $Architecture = 0

    # Software Release / Ring / Channel / Type ?!
    # Citrix Workspace App
    # 0 = Current Release
    # 1 = Long Term Service Release
    $CitrixWorkspaceAppRelease = 1

    # Microsoft 365 Apps
    # 0 = Current (Preview) Channel
    # 1 = Current Channel
    # 2 = Monthly Enterprise Channel
    # 3 = Semi-Annual Enterprise (Preview) Channel
    # 4 = Semi-Annual Enterprise Channel
    $MS365AppsChannel = 4

    # Microsoft OneDrive
    # 0 = Insider Ring
    # 1 = Production Ring
    # 2 = Enterprise Ring
    $MSOneDriveRing = 2

    # Microsoft Teams
    # 0 = Preview Ring
    # 1 = General Ring
    $MSTeamsRing = 1

    # Mozilla Firefox
    # 0 = Current
    # 1 = ESR
    $MSTeamsRing = 0

    # TreeSize
    # 0 = Free
    # 1 = Professional
    $TreeSizeType = 0

    # Select software
    # 0 = Not selected
    # 1 = Selected
    $7ZIP = 0
    $AdobeProDC = 0 # Only Update @ the moment
    $AdobeReaderDC = 0
    $BISF = 0
    $Citrix_Hypervisor_Tools = 0
    $Citrix_WorkspaceApp = 0
    $Filezilla = 0
    $Firefox = 0
    $Foxit_Reader = 0  # No Silent Install
    $FSLogix = 0
    $GoogleChrome = 0
    $Greenshot = 0
    $KeePass = 0
    $mRemoteNG = 0
    $MS365Apps = 0 # Automatically created install.xml is used. Please replace this file if you want to change the installation.
    $MSEdge = 0
    $MSOffice2019 = 0 # Automatically created install.xml is used. Please replace this file if you want to change the installation.
    $MSOneDrive = 0
    $MSTeams = 0
    $NotePadPlusPlus = 0
    $OpenJDK = 0
    $OracleJava8 = 0
    $TreeSizeFree = 0
    $VLCPlayer = 0
    $VMWareTools = 0
    $WinSCP = 0
    
}
else {
    Clear-Variable -name 7ZIP,AdobeProDC,AdobeReaderDC,BISF,Citrix_Hypervisor_Tools,Filezilla,Firefox,Foxit_Reader,FSLogix,Greenshot,GoogleChrome,KeePass,mRemoteNG,MS365Apps,MSEdge,MSOffice2019,MSTeams,NotePadPlusPlus,MSOneDrive,OpenJDK,OracleJava8,TreeSizeFree,VLCPlayer,VMWareTools,WinSCP,Citrix_WorkspaceApp,Architecture,FirefoxChannel,CitrixWorkspaceAppRelease,Language,MS365AppsChannel,MSOneDriveRing,MSTeamsRing,TreeSizeType -ErrorAction SilentlyContinue
    gui_mode
}


# Disable progress bar while downloading
$ProgressPreference = 'SilentlyContinue'

# Variable definition (Architecture,Language etc)
switch ($Architecture) {
    0 { $ArchitectureClear = 'x64'}
    1 { $ArchitectureClear = 'x86'}
}

switch ($Language) {
    0 { $LanguageClear = 'Danish'}
    1 { $LanguageClear = 'Dutch'}
    2 { $LanguageClear = 'English'}
    3 { $LanguageClear = 'Finnish'}
    4 { $LanguageClear = 'French'}
    5 { $LanguageClear = 'German'}
    6 { $LanguageClear = 'Italian'}
    7 { $LanguageClear = 'Japanese'}
    8 { $LanguageClear = 'Korean'}
    9 { $LanguageClear = 'Norwegian'}
    10 { $LanguageClear = 'Polish'}
    11 { $LanguageClear = 'Portuguese'}
    12 { $LanguageClear = 'Russian'}
    13 { $LanguageClear = 'Spanish'}
    14 { $LanguageClear = 'Swedish'}
}

if ($install -eq $False) {
    # Install/Update Evergreen module
    Write-Output ""
    Write-Verbose "Installing/updating Evergreen module... please wait" -Verbose
    Write-Output ""
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
    if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
    Update-Module Evergreen -force

    Write-Output "Starting downloads..."
    Write-Output ""

    # Download 7-ZIP
    if ($7ZIP -eq 1) {
        $Product = "7-Zip"
        $PackageName = "7-Zip_" + "$ArchitectureClear"
        $7ZipD = Get-7zip | Where-Object { $_.Architecture -eq "$ArchitectureClear" -and $_.URI -like "*exe*" }
        $Version = $7ZipD.Version
        $URL = $7ZipD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $VersionPath = "$PSScriptRoot\$Product\Version_" + "$ArchitectureClear" + ".txt"
        $CurrentVersion = Get-Content -Path "$VersionPath" -EA SilentlyContinue
        Write-Verbose "Download $Product $ArchitectureClear" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$VersionPath" -Value "$Version"
            Write-Verbose "Starting Download of $Product $ArchitectureClear $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Adobe Pro DC Update
    if ($AdobeProDC -eq 1) {
        $Product = "Adobe Pro DC"
        $PackageName = "Adobe_Pro_DC_Update"
        $AdobeProD = Get-AdobeAcrobat | Where-Object { $_.Type -eq "Updater" -and $_.Track -eq "DC" }
        $Version = $AdobeProD.Version
        $URL = $AdobeProD.uri
        $InstallerType = "msp"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Include *.msp, *.log, Version.txt, Download* -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source)) 
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Adobe Reader DC
    if ($AdobeReaderDC -eq 1) {
        $Product = "Adobe Reader DC"
        $PackageName = "Adobe_Reader_DC_"
        $AdobeLanguageClear = $LanguageClear
        switch ($LanguageClear) {
            Polish { $AdobeLanguageClear = 'English'}
            Portuguese { $AdobeLanguageClear = 'English'}
            Russian { $AdobeLanguageClear = 'English'}
            Swedish { $AdobeLanguageClear = 'English'}
        }
        $AdobeReaderD = Get-AdobeAcrobatReaderDC | Where-Object {$_.Type -eq "Installer" -and $_.Language -eq "$AdobeLanguageClear"}
        $Version = $AdobeReaderD.Version
        $URL = $AdobeReaderD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "$AdobeLanguageClear" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product $AdobeLanguageClear" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) {New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null}
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Include *.msp, *.log, Version.txt, Download* -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $AdobeLanguageClear $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source)) 
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download BIS-F
    if ($BISF -eq 1) {
        $Product = "BIS-F"
        $PackageName = "setup-BIS-F"
        $BISFD = Get-BISF | Where-Object { $_.URI -like "*msi*" }
        $Version = $BISFD.Version
        $URL = $BISFD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Exclude *.ps1, *.lnk -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Citrix Hypervisor Tools
    if ($Citrix_Hypervisor_Tools -eq 1) {
        $Product = "Citrix Hypervisor Tools"
        $PackageName = "managementagentx64"
        $CitrixHypervisor = Get-CitrixVMTools | Where-Object {$_.Architecture -eq "x64"} | Select-Object -Last 1
        $Version = $CitrixHypervisor.Version
        $URL = $CitrixHypervisor.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\Citrix\$Product")) { New-Item -Path "$PSScriptRoot\Citrix\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\Citrix\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\Citrix\$Product\*" -Recurse
            Start-Transcript $LogPS
            New-Item -Path "$PSScriptRoot\Citrix\$Product" -Name "Download date $Date" | Out-Null
            Set-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\Citrix\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Citrix WorkspaceApp Current
    if ($Citrix_WorkspaceApp_CR -eq 1) {
        $Product = "Citrix WorkspaceApp Current Release"
        $PackageName = "CitrixWorkspaceApp"
        $WSACD = Get-CitrixWorkspaceApp | Where-Object { $_.Title -like "*Workspace*" -and "*Current*" -and $_.Platform -eq "Windows" -and $_.Title -like "*Current*" }
        $Version = $WSACD.Version
        $URL = $WSACD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -EA SilentlyContinue
        if (!(Test-Path -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility")) { New-Item -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility" -ItemType Directory | Out-Null }
        if (!(Test-Path -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.exe")) {
            Write-Verbose "Download Citrix Receiver Cleanup Utility" -Verbose
            Invoke-WebRequest -Uri https://fileservice.citrix.com/downloadspecial/support/article/CTX137494/downloads/ReceiverCleanupUtility.zip -OutFile ("$PSScriptRoot\Citrix\ReceiverCleanupUtility\" + "ReceiverCleanupUtility.zip")
            Expand-Archive -path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.zip" -destinationpath "$PSScriptRoot\Citrix\ReceiverCleanupUtility\"
            Remove-Item -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.zip" -Force
            Write-Verbose "Download Citrix Receiver Cleanup Utility finished" -Verbose
        }
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\Citrix\$Product")) { New-Item -Path "$PSScriptRoot\Citrix\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\Citrix\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\Citrix\$Product\*" -Recurse
            Start-Transcript $LogPS
            New-Item -Path "$PSScriptRoot\Citrix\$Product" -Name "Download date $Date" | Out-Null
            Set-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\Citrix\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Citrix WorkspaceApp LTSR
    if ($Citrix_WorkspaceApp_LTSR -eq 1) {
        $Product = "Citrix WorkspaceApp LTSR"
        $PackageName = "CitrixWorkspaceApp"
        $WSALD = Get-CitrixWorkspaceApp | Where-Object { $_.Title -like "*Workspace*" -and "*LTSR*" -and $_.Platform -eq "Windows" -and $_.Title -like "*LTSR*" }
        $Version = $WSALD.Version
        $URL = $WSALD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -EA SilentlyContinue
        if (!(Test-Path -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility")) { New-Item -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility" -ItemType Directory | Out-Null }
        if (!(Test-Path -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.exe")) {
            Write-Verbose "Download Citrix Receiver Cleanup Utility" -Verbose
            Invoke-WebRequest -Uri https://fileservice.citrix.com/downloadspecial/support/article/CTX137494/downloads/ReceiverCleanupUtility.zip -OutFile ("$PSScriptRoot\Citrix\ReceiverCleanupUtility\" + "ReceiverCleanupUtility.zip")
            Expand-Archive -path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.zip" -destinationpath "$PSScriptRoot\Citrix\ReceiverCleanupUtility\"
            Remove-Item -Path "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.zip" -Force
            Write-Verbose "Download Citrix Receiver Cleanup Utility finished" -Verbose
        }
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\Citrix\$Product")) { New-Item -Path "$PSScriptRoot\Citrix\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\Citrix\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\Citrix\$Product\*" -Recurse
            Start-Transcript $LogPS
            New-Item -Path "$PSScriptRoot\Citrix\$Product" -Name "Download date $Date" | Out-Null
            Set-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\Citrix\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Filezilla
    if ($Filezilla -eq 1) {
        $Product = "Filezilla"
        $PackageName = "Filezilla-win64"
        $FilezillaD = Get-Filezilla | Where-Object { $_.URI -like "*win64*"}
        $Version = $FilezillaD.Version
        $URL = $FilezillaD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

   # Download Firefox
   if ($Firefox -eq 1) {
        $Product = "Firefox"
        $PackageName = "Firefox_Setup_x64_enUS"
        $FirefoxD = Get-MozillaFirefox | Where-Object { $_.Type -eq "msi" -and $_.Architecture -eq "x64" -and $_.Channel -eq "LATEST_FIREFOX_VERSION" -and $_.Language -eq "en-US"}
        $Version = $FirefoxD.Version
        $URL = $FirefoxD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Foxit Reader
    if ($Foxit_Reader -eq 1) {
        $Product = "Foxit Reader"
        $PackageName = "FoxitReader-Setup-English"
        $Foxit_ReaderD = Get-FoxitReader | Where-Object {$_.Language -eq "English"}
        $Version = $Foxit_ReaderD.Version
        $URL = $Foxit_ReaderD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download FSLogix
    if ($FSLogix -eq 1) {
        $Product = "FSLogix"
        $PackageName = "FSLogixAppsSetup"
        $FSLogixD = Get-MicrosoftFSLogixApps
        $Version = $FSLogixD.Version
        $URL = $FSLogixD.uri
        $InstallerType = "zip"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Install\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product\Install")) { New-Item -Path "$PSScriptRoot\$Product\Install" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\Install\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\Install\*" -Recurse
            Start-Transcript $LogPS
            New-Item -Path "$PSScriptRoot\$Product\Install" -Name "Download date $Date" | Out-Null
            Set-Content -Path "$PSScriptRoot\$Product\Install\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\Install\" + ($Source))
            expand-archive -path "$PSScriptRoot\$Product\Install\FSLogixAppsSetup.zip" -destinationpath "$PSScriptRoot\$Product\Install"
            Remove-Item -Path "$PSScriptRoot\$Product\Install\FSLogixAppsSetup.zip" -Force
            Move-Item -Path "$PSScriptRoot\$Product\Install\x64\Release\*" -Destination "$PSScriptRoot\$Product\Install"
            Remove-Item -Path "$PSScriptRoot\$Product\Install\Win32" -Force -Recurse
            Remove-Item -Path "$PSScriptRoot\$Product\Install\x64" -Force -Recurse
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Greenshot
    if ($Greenshot -eq 1) {
        $Product = "Greenshot"
        $PackageName = "Greenshot-INSTALLER-x86"
        $GreenshotD = Get-Greenshot | Where-Object { $_.Architecture -eq "x86" -and $_.URI -like "*INSTALLER*" -and $_.Type -like "exe"}
        $Version = $GreenshotD.Version
        $URL = $GreenshotD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Google Chrome
    if ($GoogleChrome -eq 1) {
        $Product = "Google Chrome"
        $ChromeURL = Get-GoogleChrome | Where-Object { $_.Architecture -eq "x64" } | Select-Object -ExpandProperty URI
        $Version = (Get-GoogleChrome | Where-Object { $_.Architecture -eq "x64" }).Version
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $ChromeURL -OutFile ("$PSScriptRoot\$Product\" + ($ChromeURL | Split-Path -Leaf))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download KeePass
    if ($KeePass -eq 1) {
        $Product = "KeePass"
        $PackageName = "KeePass"
        $KeePassD = Get-KeePass | Where-Object { $_.URI -like "*msi*" }
        $Version = $KeePassD.Version
        $URL = $KeePassD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download mRemoteNG
    if ($mRemoteNG -eq 1) {
        $Product = "mRemoteNG"
        $PackageName = "mRemoteNG"
        $mRemoteNGD = Get-mRemoteNG | Where-Object { $_.URI -like "*msi*" }
        $Version = $mRemoteNGD.Version
        $URL = $mRemoteNGD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download MS 365 Apps
    if ($MS365Apps -eq 1) {
        $Product = "MS 365 Apps (Semi Annual Channel)"
        $PackageName = "setup"
        $MS365AppsD = Get-Microsoft365Apps | Where-Object {$_.Channel -eq "Semi-Annual Channel"}
        $Version = $MS365AppsD.Version
        $URL = $MS365AppsD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product setup file" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!(Test-Path -Path "$PSScriptRoot\$Product")) {New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null}
        if (!(Test-Path "$PSScriptRoot\$Product\remove.xml" -PathType leaf)) {
            Write-Verbose "Create remove.xml" -Verbose
            [System.XML.XMLDocument]$XML=New-Object System.XML.XMLDocument
            [System.XML.XMLElement]$Root = $XML.CreateElement("Configuration")
                $XML.appendChild($Root) | out-null
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Remove"))
                $Node1.SetAttribute("All","True")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Display"))
                $Node1.SetAttribute("Level","None")
                $Node1.SetAttribute("AcceptEULA","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","AUTOACTIVATE")
                $Node1.SetAttribute("Value","0")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","FORCEAPPSHUTDOWN")
                $Node1.SetAttribute("Value","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","SharedComputerLicensing")
                $Node1.SetAttribute("Value","0")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","PinIconsToTaskbar")
                $Node1.SetAttribute("Value","FALSE")
            $XML.Save("$PSScriptRoot\$Product\remove.xml")
            Write-Verbose "Create remove.xml finished!" -Verbose
        }
        if (!(Test-Path "$PSScriptRoot\$Product\install.xml" -PathType leaf)) {
            Write-Verbose "Create install.xml" -Verbose
            [System.XML.XMLDocument]$XML=New-Object System.XML.XMLDocument
            [System.XML.XMLElement]$Root = $XML.CreateElement("Configuration")
                $XML.appendChild($Root) | out-null
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Add"))
                $Node1.SetAttribute("SourcePath","$PSScriptRoot\$Product")
                $Node1.SetAttribute("OfficeClientEdition","64")
                $Node1.SetAttribute("Channel","SemiAnnual")
            [System.XML.XMLElement]$Node2 = $Node1.AppendChild($XML.CreateElement("Product"))
                $Node2.SetAttribute("ID","O365ProPlusRetail")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("Language"))
                $Node3.SetAttribute("ID","MatchOS")
                $Node3.SetAttribute("Fallback","en-us")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Teams")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Lync")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Groove")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","OneDrive")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Display"))
                $Node1.SetAttribute("Level","None")
                $Node1.SetAttribute("AcceptEULA","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Logging"))
                $Node1.SetAttribute("Level","Standard")
                $Node1.SetAttribute("Path","%temp%")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","SharedComputerLicensing")
                $Node1.SetAttribute("Value","1")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","FORCEAPPSHUTDOWN")
                $Node1.SetAttribute("Value","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Updates"))
                $Node1.SetAttribute("Enabled","FALSE")
                $XML.Save("$PSScriptRoot\$Product\install.xml")
            Write-Verbose "Create install.xml finished!" -Verbose
        }
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse -Exclude install.xml,remove.xml
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version setup file" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
        # Download Apps 365 install files
        if (!(Test-Path -Path "$PSScriptRoot\$Product\Office\Data\$Version")) {
            Write-Verbose "Download $Product $Version install files" -Verbose
            $DApps365 = @(
                "/download install.xml"
            )
            set-location $PSScriptRoot\$Product
            Start-Process ".\setup.exe" -ArgumentList $DApps365 -wait -NoNewWindow
            set-location $PSScriptRoot
            Write-Output ""
        }
    }

    # Download MS Edge
    if ($MSEdge -eq 1) {
        $Product = "MS Edge"
        $EdgeURL = Get-MicrosoftEdge | Where-Object { $_.Platform -eq "Windows" -and $_.Channel -eq "stable" -and $_.Architecture -eq "x64" }
        $EdgeURL = $EdgeURL | Sort-Object -Property Version -Descending | Select-Object -First 1
        $Version = (Get-MicrosoftEdge | Where-Object { $_.Platform -eq "Windows" -and $_.Channel -eq "stable" -and $_.Architecture -eq "x64" }).Version
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue 
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $EdgeURL.Uri -OutFile ("$PSScriptRoot\$Product\" + ($EdgeURL.URI | Split-Path -Leaf))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download MS Office 2019
    if ($MSOffice2019 -eq 1) {
        $Product = "MS Office 2019"
        $PackageName = "setup"
        $MSOffice2019D = Get-Microsoft365Apps | Where-Object {$_.Channel -eq "Office 2019 Enterprise"}
        $Version = $MSOffice2019D.Version
        $URL = $MSOffice2019D.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product setup file" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!(Test-Path -Path "$PSScriptRoot\$Product")) {New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null}
        if (!(Test-Path "$PSScriptRoot\$Product\remove.xml" -PathType leaf)) {
            Write-Verbose "Create remove.xml" -Verbose
            [System.XML.XMLDocument]$XML=New-Object System.XML.XMLDocument
            [System.XML.XMLElement]$Root = $XML.CreateElement("Configuration")
                $XML.appendChild($Root) | out-null
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Remove"))
                $Node1.SetAttribute("All","True")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Display"))
                $Node1.SetAttribute("Level","None")
                $Node1.SetAttribute("AcceptEULA","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","AUTOACTIVATE")
                $Node1.SetAttribute("Value","0")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","FORCEAPPSHUTDOWN")
                $Node1.SetAttribute("Value","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","SharedComputerLicensing")
                $Node1.SetAttribute("Value","0")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","PinIconsToTaskbar")
                $Node1.SetAttribute("Value","FALSE")
            $XML.Save("$PSScriptRoot\$Product\remove.xml")
            Write-Verbose "Create remove.xml finished!" -Verbose
        }
        if (!(Test-Path "$PSScriptRoot\$Product\install.xml" -PathType leaf)) {
            Write-Verbose "Create install.xml" -Verbose
            [System.XML.XMLDocument]$XML=New-Object System.XML.XMLDocument
            [System.XML.XMLElement]$Root = $XML.CreateElement("Configuration")
                $XML.appendChild($Root) | out-null
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Add"))
                $Node1.SetAttribute("SourcePath","$PSScriptRoot\$Product")
                $Node1.SetAttribute("OfficeClientEdition","64")
                $Node1.SetAttribute("Channel","PerpetualVL2019")
            [System.XML.XMLElement]$Node2 = $Node1.AppendChild($XML.CreateElement("Product"))
                $Node2.SetAttribute("ID","ProPlus2019Volume")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("Language"))
                $Node3.SetAttribute("ID","MatchOS")
                $Node3.SetAttribute("Fallback","en-us")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Teams")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Lync")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","Groove")
            [System.XML.XMLElement]$Node3 = $Node2.AppendChild($XML.CreateElement("ExcludeApp"))
                $Node3.SetAttribute("ID","OneDrive")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Display"))
                $Node1.SetAttribute("Level","None")
                $Node1.SetAttribute("AcceptEULA","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Logging"))
                $Node1.SetAttribute("Level","Standard")
                $Node1.SetAttribute("Path","%temp%")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","SharedComputerLicensing")
                $Node1.SetAttribute("Value","1")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Property"))
                $Node1.SetAttribute("Name","FORCEAPPSHUTDOWN")
                $Node1.SetAttribute("Value","TRUE")
            [System.XML.XMLElement]$Node1 = $Root.AppendChild($XML.CreateElement("Updates"))
                $Node1.SetAttribute("Enabled","FALSE")
                $XML.Save("$PSScriptRoot\$Product\install.xml")
            Write-Verbose "Create install.xml finished!" -Verbose
        }
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse -Exclude install.xml,remove.xml
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
        # Download MS Office 2019 install files
        if (!(Test-Path -Path "$PSScriptRoot\$Product\Office\Data\$Version")) {
            Write-Verbose "Download $Product $Version install files" -Verbose
            $DOffice2019 = @(
                "/download install.xml"
            )
            set-location $PSScriptRoot\$Product
            Start-Process ".\setup.exe" -ArgumentList $DOffice2019 -wait -NoNewWindow
            set-location $PSScriptRoot
            Write-Output ""
        }
    }

    # Download MS OneDrive
    if ($MSOneDrive -eq 1) {
        $Product = "MS OneDrive"
        $PackageName = "OneDriveSetup"
        $MSOneDriveD = Get-MicrosoftOneDrive | Where-Object { $_.Ring -eq "Production" -and $_.Type -eq "Exe" } | Sort-Object -Property Version -Descending | Select-Object -Last 1
        $Version = $MSOneDriveD.Version
        $URL = $MSOneDriveD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download MS Teams
    if ($MSTeams -eq 1) {
        $Product = "MS Teams"
        $PackageName = "Teams_windows_x64"
        $TeamsD = Get-MicrosoftTeams | Where-Object { $_.Architecture -eq "x64" -and $_.Ring -eq "General"}
        $Version = $TeamsD.Version
        $URL = $TeamsD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Include *.msi, *.log, Version.txt, Download* -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Notepad ++
    if ($NotePadPlusPlus -eq 1) {
        $Product = "NotePadPlusPlus"
        $PackageName = "NotePadPlusPlus_x64"
        $NotepadD = Get-NotepadPlusPlus | Where-Object { $_.Architecture -eq "x64" -and $_.URI -match ".exe" }
        $Version = $NotepadD.Version
        $URL = $NotepadD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Get-ChildItem "$PSScriptRoot\$Product\" -Exclude lang | Remove-Item -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download openJDK
    if ($OpenJDK -eq 1) {
        $Product = "open JDK"
        $PackageName = "OpenJDK"
        $OpenJDKD = Get-OpenJDK | Where-Object { $_.Architecture -eq "x64" -and $_.URI -like "*msi*" } | Sort-Object -Property Version -Descending | Select-Object -First 1
        $Version = $OpenJDKD.Version
        $URL = $OpenJDKD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download OracleJava8
    if ($OracleJava8 -eq 1) {
        $Product = "Oracle Java 8"
        $PackageName = "Oracle Java 8"
        $OracleJava8D = Get-OracleJava8 | Where-Object { $_.Architecture -eq "x64" }
        $Version = $OracleJava8D.Version
        $URL = $OracleJava8D.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download Tree Size Free
    if ($TreeSizeFree -eq 1) {
        $Product = "TreeSizeFree"
        $PackageName = "TreeSizeFree"
        $TreeSizeFreeD = Get-JamTreeSizeFree
        $Version = $TreeSizeFreeD.Version
        $URL = $TreeSizeFreeD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download VLC Player
    if ($VLCPlayer -eq 1) {
        $Product = "VLC Player"
        $PackageName = "VLC-Player"
        $VLCD = Get-VideoLanVlcPlayer | Where-Object { $_.Platform -eq "Windows" -and $_.Architecture -eq "x64" -and $_.Type -eq "MSI" }
        $Version = $VLCD.Version
        $URL = $VLCD.uri
        $InstallerType = "msi"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download VMWareTools
    if ($VMWareTools -eq 1) {
        $Product = "VMWare Tools"
        $PackageName = "VMWareTools"
        $VMWareToolsD = Get-VMwareTools | Where-Object { $_.Architecture -eq "x64" }
        $Version = $VMWareToolsD.Version
        $URL = $VMWareToolsD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) { New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null }
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product $Version" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Verbose "Download of the new version $Version finished" -Verbose
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }

    # Download WinSCP
    if ($WinSCP -eq 1) {
        $Product = "WinSCP"
        $PackageName = "WinSCP"
        $WinSCPD = Get-WinSCP | Where-Object {$_.URI -like "*Setup*"}
        $Version = $WinSCPD.Version
        $URL = $WinSCPD.uri
        $InstallerType = "exe"
        $Source = "$PackageName" + "." + "$InstallerType"
        $CurrentVersion = Get-Content -Path "$PSScriptRoot\$Product\Version.txt" -EA SilentlyContinue
        Write-Verbose "Download $Product" -Verbose
        Write-Host "Download Version: $Version"
        Write-Host "Current Version: $CurrentVersion"
        if (!($CurrentVersion -eq $Version)) {
            Write-Verbose "Update available" -Verbose
            if (!(Test-Path -Path "$PSScriptRoot\$Product")) {New-Item -Path "$PSScriptRoot\$Product" -ItemType Directory | Out-Null}
            $LogPS = "$PSScriptRoot\$Product\" + "$Product $Version.log"
            Remove-Item "$PSScriptRoot\$Product\*" -Recurse
            Start-Transcript $LogPS
            Set-Content -Path "$PSScriptRoot\$Product\Version.txt" -Value "$Version"
            Write-Verbose "Starting Download of $Product.txt" -Verbose
            Invoke-WebRequest -Uri $URL -OutFile ("$PSScriptRoot\$Product\" + ($Source))
            Write-Verbose "Stop logging" -Verbose
            Stop-Transcript
            Write-Output ""
        }
        else {
            Write-Verbose "No new version available" -Verbose
            Write-Output ""
        }
    }
}

if ($download -eq $False) {

    # FUNCTION Logging
    #========================================================================================================================================
    Function DS_WriteLog {
        
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory=$true, Position = 0)][ValidateSet("I","S","W","E","-",IgnoreCase = $True)][String]$InformationType,
            [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
            [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
        )
        begin {
        }
        process {
            $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
            if ( $Text -eq "" ) {
                Add-Content $LogFile -value ("") # Write an empty line
            } Else {
                Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
            }
        }
        end {
        }
    }

    # Logging
    # Global variables
    #$StartDir = $PSScriptRoot # the directory path of the script currently being executed
    $LogDir = "$PSScriptRoot\_Install Logs"
    $LogFileName = ("$ENV:COMPUTERNAME.log")
    $LogFile = Join-path $LogDir $LogFileName

    # Create the log directory if it does not exist
    if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

    # Create new log file (overwrite existing one)
    New-Item $LogFile -ItemType "file" -force | Out-Null
    DS_WriteLog "I" "START SCRIPT - " $LogFile
    DS_WriteLog "-" "" $LogFile
    #========================================================================================================================================
    
    # define Error handling
    # note: do not change these values
    $global:ErrorActionPreference = "Stop"
    if ($verbose){ $global:VerbosePreference = "Continue" }


    # Install 7-ZIP
    if ($7ZIP -eq 1) {
        $Product = "7-Zip"

        # Check, if a new version is available
        $VersionPath = "$PSScriptRoot\$Product\Version_" + "$ArchitectureClear" + ".txt"
        $Version = Get-Content -Path "$VersionPath"
        $SevenZip = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*7-Zip*"}).DisplayVersion | Select-Object -First 1
        $7ZipInstaller = "7-Zip_" + "$ArchitectureClear" + ".exe"
        if ($SevenZip -ne $Version) {
            # 7-Zip
            Write-Verbose "Installing $Product $ArchitectureClear" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                Start-Process "$PSScriptRoot\$Product\$7ZipInstaller" –ArgumentList /S
                $p = Get-Process 7-Zip_$ArchitectureClear
                if ($p) {
                    $p.WaitForExit()
                    Write-Verbose "Installation $Product $ArchitectureClear finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Adobe Pro DC
    if ($AdobeProDC -eq 1) {
        $Product = "Adobe Pro DC"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Adobe = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Adobe Acrobat Reader*"}).DisplayVersion
        if ($Adobe -ne $Version) {
            # Adobe Pro DC
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                $mspArgs = "/P `"$PSScriptRoot\$Product\Adobe_Pro_DC_Update.msp`" /quiet /qn"
                $inst = Start-Process -FilePath msiexec.exe -ArgumentList $mspArgs -Wait
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
                # Update Dienst und Task deaktivieren
                Write-Verbose "Customize Service and Scheduled Task" -Verbose
                Stop-Service AdobeARMservice
                Set-Service AdobeARMservice -StartupType Disabled
                Write-Verbose "Stop and Disable Service $Product finished!" -Verbose
                Disable-ScheduledTask -TaskName "Adobe Acrobat Update Task" | Out-Null
                Write-Verbose "Disable Scheduled Task $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installinng $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Adobe Reader DC
    if ($AdobeReaderDC -eq 1) {
        $Product = "Adobe Reader DC"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Adobe = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Adobe Acrobat Reader*"}).DisplayVersion
        $AdobeReaderInstaller = "Adobe_Reader_DC_" + "$AdobeLanguageClear" + ".exe"
        if ($Adobe -ne $Version) {
            # Adobe Reader DC
            Write-Verbose "Installing $Product $AdobeLanguageClear" -Verbose
            DS_WriteLog "I" "Installing $Product $AdobeLanguageClear" $LogFile
            $Options = @(
                "/sAll"
                "/rs"
            )
            try	{
                Start-Process "$PSScriptRoot\$Product\$AdobeReaderInstaller" –ArgumentList $Options
                $p = Get-Process Adobe_Reader_DC_$AdobeLanguageClear
                if ($p) {
                    $p.WaitForExit()
                    Write-Verbose "Installation $Product $AdobeLanguageClear finished!" -Verbose
                }
                # Update Dienst und Task deaktivieren
                Write-Verbose "Customize Service and Scheduled Task" -Verbose
                Stop-Service AdobeARMservice
                Set-Service AdobeARMservice -StartupType Disabled
                Write-Verbose "Stop and Disable Service $Product finished!" -Verbose
                Disable-ScheduledTask -TaskName "Adobe Acrobat Update Task" | Out-Null
                Write-Verbose "Disable Scheduled Task $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install BIS-F
    if ($BISF -eq 1) {
        $Product = "BIS-F"
        
        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSiFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $BISF = (Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Base Image*"}).DisplayVersion | Sort-Object -Property Version -Descending | Select-Object -First 1
        IF ($BISF) {$BISF = $BISF -replace ".{6}$"}
        IF ($BISF -ne $Version) {
            # Base Image Script Framework
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\setup-BIS-F.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            write-Output ""
            # Customize scripts, it's best practise to enable Task Offload and RSS and to disable DEP
            write-Verbose "Customize scripts $Product" -Verbose
            DS_WriteLog "I" "Customize scripts $Product" $LogFile
            $BISFDir = "C:\Program Files (x86)\Base Image Script Framework (BIS-F)\Framework\SubCall"
            try {
                ((Get-Content "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1" -Raw) -replace "DisableTaskOffload' -Value '1'","DisableTaskOffload' -Value '0'") | Set-Content -Path "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1"
                ((Get-Content "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1" -Raw) -replace 'nx AlwaysOff','nx OptOut') | Set-Content -Path "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1"
                ((Get-Content "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1" -Raw) -replace 'rss=disable','rss=enable') | Set-Content -Path "$BISFDir\Preparation\97_PrepBISF_PRE_BaseImage.ps1"
                Write-Verbose "Customize scripts $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error when customizing scripts (error: $($Error[0]))" $LogFile
            }
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
        DS_WriteLog "-" "" $LogFile
        write-Output ""
    }

    # Install Citrix Hypervisor Tools
    IF ($Citrix_Hypervisor_Tools -eq 1) {
        $Product = "Citrix Hypervisor Tools"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/quiet"
                "/norestart"
                )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if ($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt"
        $HypTools = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Citrix Hypervisor*"}).DisplayVersion
        $HypTools = $HypTools.Insert(3,'.0')
        IF ($HypTools -ne $Version) {
            # Citrix Hypervisor Tools
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\Citrix\$Product\managementagentx64.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Citrix WorkspaceApp Current
    IF ($Citrix_WorkspaceApp_CR -eq 1) {
        $Product = "Citrix WorkspaceApp Current Release"
        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt"
        $WSA = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Citrix Workspace*" -and $_.UninstallString -like "*Trolley*"}).DisplayVersion
        $UninstallWSACR = "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.exe"
        IF ($WSA -ne $Version) {
            # Citrix WSA Uninstallation
            Write-Verbose "Uninstalling Citrix Workspace App / Receiver" -Verbose
            DS_WriteLog "I" "Uninstalling Citrix Workspace App / Receiver" $LogFile
            try	{
                Start-process $UninstallWSACR -ArgumentList '/silent /disableCEIP' –NoNewWindow -Wait
            } catch {
                DS_WriteLog "E" "Error Uninstalling Citrix Workspace App / Receiver (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Verbose "Uninstalling and Cleanup Citrix Workspace App / Receiver finished!" -Verbose

            # Citrix WSA Installation
            $Options = @(
                "/forceinstall"
                "/silent"
                "/EnableCEIP=false"
                "/FORCE_LAA=1"
                "/AutoUpdateCheck=disabled"
                "/EnableCEIP=false"
                "/ALLOWADDSTORE=S"
                "/ALLOWSAVEPWD=S"
                "/includeSSON"
                "/ENABLE_SSON=Yes"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\Citrix\$Product\CitrixWorkspaceApp.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
                Write-Verbose "Customize $Product" -Verbose
                reg add "HKLM\SOFTWARE\Wow6432Node\Policies\Citrix" /v EnableX1FTU /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Citrix\Splashscreen" /v SplashscrrenShown /d 1 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Citrix" /f /v EnableFTU /t REG_DWORD /d 0 | Out-Null
                Write-Verbose "Customizing $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Verbose " ... ready!" -Verbose
            Write-Verbose "Server needs to reboot after installation!" -Verbose
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Citrix WorkspaceApp LTSR
    IF ($Citrix_WorkspaceApp_LTSR -eq 1) {
        $Product = "Citrix WorkspaceApp LTSR"
        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\Citrix\$Product\Version.txt"
        $UninstallWSALTSR = "$PSScriptRoot\Citrix\ReceiverCleanupUtility\ReceiverCleanupUtility.exe"
        $WSA = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Citrix Workspace*" -and $_.UninstallString -like "*Trolley*"}).DisplayVersion
        IF ($WSA -ne $Version) {
            # Citrix WSA Uninstallation
            Write-Verbose "Uninstalling Citrix Workspace App / Receiver" -Verbose
            DS_WriteLog "I" "Uninstalling Citrix Workspace App / Receiver" $LogFile
            try	{
                Start-process $UninstallWSALTSR -ArgumentList '/silent /disableCEIP' –NoNewWindow -Wait
            } catch {
                DS_WriteLog "E" "Error Uninstalling Citrix Workspace App / Receiver (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Verbose "Uninstalling and Cleanup Citrix Workspace App / Receiver finished!" -Verbose

            # Citrix WSA Installation
            $Options = @(
                "/forceinstall"
                "/silent"
                "/EnableCEIP=false"
                "/FORCE_LAA=1"
                "/AutoUpdateCheck=disabled"
                "/EnableCEIP=false"
                "/ALLOWADDSTORE=S"
                "/ALLOWSAVEPWD=S"
                "/includeSSON"
                "/ENABLE_SSON=Yes"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\Citrix\$Product\CitrixWorkspaceApp.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
                Write-Verbose "Customize $Product" -Verbose
                reg add "HKLM\SOFTWARE\Wow6432Node\Policies\Citrix" /v EnableX1FTU /t REG_DWORD /d 0 /f | Out-Null
                reg add "HKCU\Software\Citrix\Splashscreen" /v SplashscrrenShown /d 1 /f | Out-Null
                reg add "HKLM\SOFTWARE\Policies\Citrix" /f /v EnableFTU /t REG_DWORD /d 0 | Out-Null
                Write-Verbose "Customizing $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Verbose " ... ready!" -Verbose
            Write-Verbose "Server needs to reboot after installation!" -Verbose
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Filezilla
    IF ($Filezilla -eq 1) {
        $Product = "Filezilla"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Filezilla = (Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Filezilla*"}).DisplayVersion
        IF ($Filezilla -ne $Version) {
            # Filezilla
            $Options = @(
                "/S"
                "/user=all"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\$Product\Filezilla-win64.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Firefox
    IF ($Firefox -eq 1) {
        $Product = "Firefox"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/q"
                "DESKTOP_SHORTCUT=false"
                "TASKBAR_SHORTCUT=false"
                "INSTALL_MAINTENANCE_SERVICE=false"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if ($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Firefox = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Firefox*"}).DisplayVersion
        IF ($Firefox -ne $Version) {
            # Firefox
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\Firefox_Setup_x64_enUS.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Foxit Reader
    IF ($Foxit_Reader -eq 1) {
        $Product = "Foxit Reader"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $FReader = (Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Foxit Reader*"}).DisplayVersion
        IF ($FReader -ne $Version) {
            # Foxit Reader
            $Options = @(
                "/VERYSILENT"
                "/ALLUSERS"
                "/NORESTART"
                "/NOCLOSEAPPLICATIONS"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\$Product\FoxitReader-Setup-English.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install FSLogix
    IF ($FSLogix -eq 1) {
        $Product = "FSLogix"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Install\Version.txt"
        $FSLogix = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps"}).DisplayVersion
        IF (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps"}) {
            $UninstallFSL = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps"}).UninstallString.replace("/uninstall","")
        }
        IF (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps RuleEditor"}) {
            $UninstallFSLRE = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps RuleEditor"}).UninstallString.replace("/uninstall","")
        }
        IF ($FSLogix -ne $Version) {
            # FSLogix Uninstall
            IF (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft FSLogix Apps"}) {
                Write-Verbose "Uninstalling $Product" -Verbose
                DS_WriteLog "I" "Uninstalling $Product" $LogFile
                try	{
                    Start-process $UninstallFSL -ArgumentList '/uninstall /quiet /norestart' –NoNewWindow -Wait
                    Start-process $UninstallFSLRE -ArgumentList '/uninstall /quiet /norestart' –NoNewWindow -Wait
                } catch {
                    DS_WriteLog "E" "Error Uninstalling $Product (error: $($Error[0]))" $LogFile
                }
                DS_WriteLog "-" "" $LogFile
                Write-Output ""
                Write-Verbose "Server needs to reboot, start script again after reboot" -Verbose
                Write-Output ""
                Write-Output "Hit any key to reboot server"
                Read-Host
                Restart-Computer
            }
            # FSLogix Install
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process "$PSScriptRoot\$Product\Install\FSLogixAppsSetup.exe" -ArgumentList '/install /norestart /quiet'  –NoNewWindow
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product Setup finished!" -Verbose
                }
                $inst = Start-Process "$PSScriptRoot\$Product\Install\FSLogixAppsRuleEditorSetup.exe" -ArgumentList '/install /norestart /quiet'  –NoNewWindow
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product Rule Editor finished!" -Verbose
                }
                reg add "HKLM\SOFTWARE\FSLogix\Profiles" /v GroupPolicyState /t REG_DWORD /d 0 /f | Out-Null
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Greenshot
    IF ($Greenshot -eq 1) {
        $Product = "Greenshot"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Greenshot = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Greenshot*"}).DisplayVersion
        IF ($Greenshot -ne $Version) {
            # Greenshot
            $Options = @(
                "/VERYSILENT"
                "/NORESTART"
                "/SUPPRESSMSGBOXES"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\$Product\Greenshot-INSTALLER-x86.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Google Chrome
    IF ($GoogleChrome -eq 1) {
        $Product = "Google Chrome"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if ($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Chrome = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Google Chrome"}).DisplayVersion
        IF ($Chrome -ne $Version) {
            # Google Chrome
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\googlechromestandaloneenterprise64.msi" | Install-MSIFile
                # Update Dienst und Task deaktivieren
                Write-Verbose "Customize Service and Scheduled Task" -Verbose
                Stop-Service gupdate
                Set-Service gupdate -StartupType Disabled
                Stop-Service gupdatem
                Set-Service gupdatem -StartupType Disabled
                Write-Verbose "Stop and Disable Service $Product finished!" -Verbose
                Disable-ScheduledTask -TaskName "GoogleUpdateTaskMachineCore" | Out-Null
                Disable-ScheduledTask -TaskName "GoogleUpdateTaskMachineUA" | Out-Null
                Disable-ScheduledTask -TaskName "GPUpdate on Startup" | Out-Null
                Write-Verbose "Disable Scheduled Task $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install KeePass
    IF ($KeePass -eq 1) {
        $Product = "KeePass"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path!"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $KeePass = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*KeePass*"}).DisplayVersion
        IF ($KeePass) {$KeePass = $KeePass -replace ".{2}$"}
        IF ($KeePass -ne $Version) {
            # KeePass
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\KeePass.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install mRemoteNG
    IF ($mRemoteNG -eq 1) {
        $Product = "mRemoteNG"
        
        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path!"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $mRemoteNG = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "mRemoteNG"}).DisplayVersion
        IF ($mRemoteNG) {$mRemoteNG = $mRemoteNG -replace ".{6}$"}
        IF ($mRemoteNG -ne $Version) {
            # mRemoteNG
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\mRemoteNG.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install MS Apps 365
    IF ($MS365Apps -eq 1) {
        $Product = "MS 365 Apps (Semi Annual Channel)"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $MS365AppsV = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Microsoft 365 Apps*"}).DisplayVersion
        IF ($MS365AppsV -ne $Version) {
            # MS365Apps Uninstallation
            $Options = @(
                "/configure remove.xml"
            )
            Write-Verbose "Uninstalling Office 2019 or Microsoft 365 Apps" -Verbose
            DS_WriteLog "I" "Uninstalling Office 2019 or Microsoft 365 Apps" $LogFile
            try	{
                set-location $PSScriptRoot\$Product
                Start-Process -FilePath ".\setup.exe" -ArgumentList $Options -NoNewWindow -wait
                set-location $PSScriptRoot
                Write-Verbose "Uninstallation Office 2019 or Microsoft 365 Apps finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error uninstalling Office 2019 or Microsoft 365 Apps (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
            # MS365Apps Installation
            $Options = @(
                "/configure install.xml"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                set-location $PSScriptRoot\$Product
                Start-Process -FilePath ".\setup.exe" -ArgumentList $Options -NoNewWindow -wait
                set-location $PSScriptRoot
                Write-Verbose "Installation $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install MS Edge
    IF ($MSEdge -eq 1) {
        $Product = "MS Edge"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
            
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
                "DONOTCREATEDESKTOPSHORTCUT=TRUE"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================
        
        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Edge = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -eq "Microsoft Edge"}).DisplayVersion
        IF ($Edge -ne $Version) {
            # MS Edge
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\MicrosoftEdgeEnterpriseX64.msi" | Install-MSIFile
                # Disable update tasks
                Write-Verbose "Customize Scheduled Task" -Verbose
                Start-Sleep -s 5
                Disable-ScheduledTask -TaskName MicrosoftEdgeUpdateTaskMachineCore | Out-Null
                Disable-ScheduledTask -TaskName MicrosoftEdgeUpdateTaskMachineUA | Out-Null
                Disable-ScheduledTask -TaskName MicrosoftEdgeUpdateBrowserReplacementTask | Out-Null
                Write-Verbose "Disable Scheduled Task $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
            # Disable Citrix API Hooks (MS Edge) on Citrix VDA
            $(
                $RegPath = "HKLM:SYSTEM\CurrentControlSet\services\CtxUvi"
                IF (Test-Path $RegPath) {
                    Write-Verbose "Disable Citrix API Hooks" -Verbose
                    $RegName = "UviProcessExcludes"
                    $EdgeRegvalue = "msedge.exe"
                    # Get current values in UviProcessExcludes
                    $CurrentValues = Get-ItemProperty -Path $RegPath | Select-Object -ExpandProperty $RegName
                    # Add the msedge.exe value to existing values in UviProcessExcludes
                    Set-ItemProperty -Path $RegPath -Name $RegName -Value "$CurrentValues$EdgeRegvalue;"
                    Write-Verbose "Disable Citrix API Hooks for $Product finished!" -Verbose
                }
            ) | Out-Null
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install MS Office 2019
    IF ($MSOffice2019 -eq 1) {
        $Product = "MS Office 2019"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $MSOffice2019V = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Microsoft Office*"}).DisplayVersion
        IF ($MSOffice2019V -ne $Version) {
            # MS Office 2019 Uninstallation
            $Options = @(
                "/configure remove.xml"
            )
            Write-Verbose "Uninstalling Office 2019 or Microsoft 365 Apps" -Verbose
            DS_WriteLog "I" "Uninstalling Office 2019 or Microsoft 365 Apps" $LogFile
            try	{
                set-location $PSScriptRoot\$Product
                Start-Process -FilePath ".\setup.exe" -ArgumentList $Options -NoNewWindow -wait
                set-location $PSScriptRoot
                Write-Verbose "Uninstallation Office 2019 or Microsoft 365 Apps finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error uninstalling Office 2019 or Microsoft 365 Apps (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
            # MS Office 2019 Installation
            $Options = @(
                "/configure install.xml"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                set-location $PSScriptRoot\$Product
                Start-Process -FilePath ".\setup.exe" -ArgumentList $Options -NoNewWindow -wait
                set-location $PSScriptRoot
                Write-Verbose "Installation $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install MS OneDrive
    IF ($MSOneDrive -eq 1) {
        $Product = "MS OneDrive"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $MSOneDriveV = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*OneDrive*"}).DisplayVersion
        IF ($MSOneDriveV -ne $Version) {
            # Installation MSOneDrive
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            $Options = @(
                "/ALLUSERS"
                "/SILENT"
            )
            try	{
                $null = Start-Process "$PSScriptRoot\$Product\OneDriveSetup.exe" –ArgumentList $Options –NoNewWindow -PassThru
                while (Get-Process -Name "OneDriveSetup" -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 10 }
                Write-Verbose "Installation $Product finished!" -Verbose
                # onedrive starts automatically after setup. kill!
                Stop-Process -Name "OneDrive" -Force
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install MS Teams
    IF ($MSTeams -eq 1) {
        $Product = "MS Teams"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "ALLUSER=1"
                "ALLUSERS=1"
                "OPTIONS='noAutoStart=true'"
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================
        
        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Teams = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Teams Machine*"}).DisplayVersion
        IF ($Teams) {$Teams = $Teams.Insert(5,'0')}
        IF ($Teams -ne $Version) {
            #Uninstalling MS Teams
            Write-Verbose "Uninstalling $Product" -Verbose
            DS_WriteLog "I" "Uninstalling $Product" $LogFile
            try {
                $UninstallTeams = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Teams Machine*"}).UninstallString
                $UninstallTeams = $UninstallTeams -Replace("MsiExec.exe /I","")
                Start-Process -FilePath msiexec.exe -ArgumentList "/X $UninstallTeams /qn"
                Start-Sleep 20
                Write-Verbose "Uninstalling $Product finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Ein Fehler ist aufgetreten beim Deinstallieren von $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            #MS Teams Installation
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\Teams_windows_x64.msi" | Install-MSIFile
                Start-Sleep 5
                # Prevents MS Teams from starting at logon, better do this with WEM or similar
                # Write-Verbose "Customize $Product Autorun" -Verbose
                # Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" -Name "Teams" -Force
                # Write-Verbose "Customize $Product Autorun finished!" -Verbose
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install Notepad ++
    IF ($NotePadPlusPlus -eq 1) {
        $Product = "NotepadPlusPlus"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Notepad = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Notepad++*"}).DisplayVersion
        IF ($Notepad -ne $Version) {
            # Installation Notepad++
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                Start-Process "$PSScriptRoot\$Product\NotePadPlusPlus_x64.exe" –ArgumentList /S –NoNewWindow
                $p = Get-Process NotePadPlusPlus_x64
		        if ($p) {
                    $p.WaitForExit()
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install OpenJDK
    IF ($OpenJDK -eq 1) {
        $Product = "open JDK"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
    
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
                "/log $PSScriptRoot\$Product\verbose.log"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $OpenJDK = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*OpenJDK*"}).DisplayVersion
        IF ($Version) {$Version = $Version -replace ".-"}
        IF ($OpenJDK -ne $Version) {
            # OpenJDK
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\OpenJDK.msi" | Install-MSIFile
                Start-Sleep 25
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install OracleJava8
    if ($OracleJava8 -eq 1) {
        $Product = "Oracle Java 8"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        IF ($Version) {$Version = $Version -replace "^.{2}"}
        IF ($Version) {$Version = $Version -replace "-.*(0)"}
        IF ($Version) {$Version = $Version -replace "._"}
        IF ($Version) {$Version = $Version -replace "\."}
        $OracleJava = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Java Auto Updater*"}).DisplayVersion
        IF ($OracleJava) {$OracleJava = $OracleJava -replace "^.{2}"}
        IF ($OracleJava) {$OracleJava = $OracleJava -replace "\."}
        if ($OracleJava -ne $Version) {
            # Oracle Java 8
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            $Options = @(
                "/s"
            )
            try	{
                Start-Process "$PSScriptRoot\$Product\Oracle Java 8.exe" –ArgumentList $Options –NoNewWindow
                $p = Get-Process "Oracle Java 8"
                if ($p) {
                    $p.WaitForExit()
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install TreeSizeFree
    IF ($TreeSizeFree -eq 1) {
        $Product = "TreeSizeFree"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $Version = $Version.Insert(3,'.')
        $TreeSize = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*TreeSize*"}).DisplayVersion
        IF ($TreeSize -ne $Version) {
            # Installation Tree Size Free
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                Start-Process "$PSScriptRoot\$Product\TreeSizeFree.exe" –ArgumentList /VerySilent –NoNewWindow -Wait
                $p = Get-Process TreeSizeFree
		        if ($p) {
                    $p.WaitForExit()
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile       
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install VLC Player
    IF ($VLCPlayer -eq 1) {
        $Product = "VLC Player"

        # FUNCTION MSI Installation
        #========================================================================================================================================
        function Install-MSIFile {
            [CmdletBinding()]
            Param(
                [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
                [ValidateNotNullorEmpty()]
                [string]$msiFile,
            
                [parameter()]
                [ValidateNotNullorEmpty()]
                [string]$targetDir
            )
            if (!(Test-Path $msiFile)) {
                throw "Path to MSI file ($msiFile) is invalid. Please check name and path"
            }
            $arguments = @(
                "/i"
                "`"$msiFile`""
                "/qn"
            )
            if ($targetDir) {
                if (!(Test-Path $targetDir)) {
                    throw "Path to installation directory $($targetDir) is invalid. Please check path and file name!"
                }
                $arguments += "INSTALLDIR=`"$targetDir`""
            }
            $inst = $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -NoNewWindow -PassThru
            if($inst -ne $null) {
                Wait-Process -InputObject $inst
                Write-Verbose "Installation $Product finished!" -Verbose
            }
            if ($process.ExitCode -eq 0) {
            }
            else {
                Write-Verbose "Installer Exit Code  $($process.ExitCode) for file  $($msifile)"
            }
        }
        #========================================================================================================================================

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $VLC = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*VLC*"}).DisplayVersion
        IF ($VLC) {$VLC = $VLC -replace ".{2}$"}
        IF ($VLC -ne $Version) {
            # VLC Player
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try {
                "$PSScriptRoot\$Product\VLC-Player.msi" | Install-MSIFile
            } catch {
                DS_WriteLog "E" "An error occurred installing $Product (error: $($Error[0]))" $LogFile 
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install VMWareTools
    IF ($VMWareTools -eq 1) {
        $Product = "VMWare Tools"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $VMWT = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*VMWare*"}).DisplayVersion
        IF ($VMWT) {$VMWT = $VMWT -replace ".{9}$"}
        IF ($VMWT -ne $Version) {
            # VMWareTools Installation
            $Options = @(
                "/s"
                "/v"
                "/qn REBOOT=Y"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\$Product\VMWareTools.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                    Write-Output ""
                    Write-Verbose "Server needs to reboot, start script again after reboot" -Verbose
                    Write-Output ""
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }

    # Install WinSCP
    IF ($WinSCP -eq 1) {
        $Product = "WinSCP"

        # Check, if a new version is available
        $Version = Get-Content -Path "$PSScriptRoot\$Product\Version.txt"
        $WSCP = (Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*WinSCP*"}).DisplayVersion
        IF ($WSCP -ne $Version) {
            # WinSCP Installation
            $Options = @(
                "/VERYSILENT"
                "/ALLUSERS"
                "/NORESTART"
                "/NOCLOSEAPPLICATIONS"
            )
            Write-Verbose "Installing $Product" -Verbose
            DS_WriteLog "I" "Installing $Product" $LogFile
            try	{
                $inst = Start-Process -FilePath "$PSScriptRoot\$Product\WinSCP.exe" -ArgumentList $Options -PassThru -ErrorAction Stop
                if($inst -ne $null) {
                    Wait-Process -InputObject $inst
                    Write-Verbose "Installation $Product finished!" -Verbose
                }
            } catch {
                DS_WriteLog "E" "Error installing $Product (error: $($Error[0]))" $LogFile
            }
            DS_WriteLog "-" "" $LogFile
            Write-Output ""
        }
        # Stop, if no new version is available
        Else {
            Write-Verbose "No Update available for $Product" -Verbose
            Write-Output ""
        }
    }
}