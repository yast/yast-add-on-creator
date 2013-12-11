#
# spec file for package yast2-add-on-creator
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-add-on-creator
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2


Group:	        System/YaST
License:        GPL-2.0
PreReq:         %fillup_prereq
Requires:	yast2 >= 2.21.22 rpm-build
BuildRequires:	perl-XML-Writer update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - module for creating Add-On product

%description
A wizard for creating your own Add-On product

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%post
%{fillup_only -n add-on-creator}

%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/add-on-creator
%{yast_yncludedir}/add-on-creator/*
%{yast_clientdir}/add-on-creator*.rb
%{yast_moduledir}/AddOnCreator.*
%{yast_moduledir}/PackagesDescr.pm
%{yast_desktopdir}/add-on-creator.desktop
%dir %{yast_ydatadir}/add-on-creator
%{yast_ydatadir}/add-on-creator/*
#agents:
%{yast_scrconfdir}/*.scr
%{yast_agentdir}/ag_*
%doc %{yast_docdir}
%doc COPYING
%{yast_fillupdir}/sysconfig.add-on-creator
