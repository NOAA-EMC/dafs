DAFS v1.0.0  RELEASE NOTES

-------
Prelude
-------

This implementation is a new standalone Domestic Aviation Forecast System (DAFS). It utilizes UPP and generates In-Flight Icing (IFI) and Graphical Turbulence Guidance (GTG) products from the High-Resolution Rapid Refresh (HRRR) model data.

Implementation Instructions
---------------------------

Though the project was transferred to NOAA-AWC, the DAFS code is still managed under the NOAA-EMC and NCAR organization spaces on GitHub.  The SPA(s) handling the DAFS implementation need to have permissions to clone the private NCAR UPP_GTG and NCAR IFI repository.  All NOAA-EMC organization repositories are publicly readable and do not require access permissions.  Please proceed with the following steps to checkout, build, and install the package on WCOSS2:

Checkout the package from GitHub and `cd` into the directory:
```bash
cd ${PACKAGEROOT}
git clone -b dafs.v1.0.0 https://github.com/noaa-emc/dafs dafs.v1.0.0
cd dafs.v1.0.0
sh sorc/checkout_upp.sh
```

The checkout procedure extracts the following DAFS components, while GTG and IFI are subcomponents of UPP.:
| Component | Revision              | POC                    |
| --------- | --------------------- | ---------------------- |
| UPP       | dafs_upp.fd @ 9a4d5d2 | Wen.Meng@noaa.gov      |
| GTG       | post_gtg.fd @ 3d35332 | Yali.Mao@noaa.gov      |
| IFI       | libIFI.fd @ 179cae1   | samuel.trahan@noaa.gov |

The GTG and IFI repositories are private and may prohib from checking out if you do not have the permission. To inquire the access, please contact the code managers with justification.

To build DAFS UPP component, execute:
```bash
sh sorc/build_upp.sh
```
The `build_upp.sh` script compiles UPP.  Runtime output from the build is written to log files in `sorc/logs` directory.

Lastly, link the `ecflow` scripts by executing:
```bash
./ecf/setup_ecf_links.sh
```

Version File
--------------------
* run.ver
No build.ver is needed, UPP component uses its own modufiles to compile.

Sorc
------------
* dafs_upp.fd

Jobs
-----------
* JDAFS_HRRR_MANAGER: uses '$dom' to differentiate calling of CONUS or ALASKA scripts
* JDAFS_HRRR_UPP: uses '$dom' to differentiate calling of CONUS or ALASKA scripts

Parm files
------------
Under parm/wmo:
* grib2.dafs.ifi* parm files are used to add WMO headers.
* grib2.*rrfs* parm files are reserved for RRFS because DAFS is going to be switched to RRFS when RRFSv2 comes operational.

Scripts
--------------
* scripts/exdafs_hrrr_alaska_upp.sh: produces icing products over ALASKA
* scripts/exdafs_hrrr_conus_upp.sh: produces icing and turbulence over CONUS
* scripts/exdafs_hrrr_alaska_manager.sh: check HRRR model data over ALASKA is available or not
* scripts/exdafs_hrrr_conus_manager.sh: check HRRR model data over CONUS is available or not
* ush/ak_subset_ifi_304m.sh: for Alaska products, thin vertical layers and add WMO headers.
* ush/conus_subset_ifi_304m.sh: for CONUS products, upscale to grid 130, thin vertical layers and add WMO headers.

Fix files
-----------
Under fix/prdgen:
1. dafs.ifi.sub304m.params is used for HRRR
2. The following files are reserved for RRFS because DAFS is going to be switched to RRFS when RRFSv2 comes operational.
*   rrfs.natlev-FAA130.params
*   rrfs.prslev-FAA130.params
*   rrfs.prslev-FAA237.params
*   rrfs.prslev-rrfs13km.params
*   rrfs.prslev-rrfs3km.params


Modules
--------------
* export hrrr_ver=v4.1
* export PrgEnvintel_ver=8.3.3
* export intel_ver=19.1.3.304
* export craype_ver=2.7.17
* export craympich_ver=8.1.19
* export craypals_ver=1.2.2
* export prod_envir_ver=2.0.6
* export libjpeg_ver=9c
* export hdf5_ver=1.10.6
* export netcdf_ver=4.7.4
* export g2tmpl_ver=1.15.0
* export prod_util_ver=2.0.14
* export grib_util_ver=1.2.4
* export wgrib2_ver=2.0.8


File Sizes
---------------------
* alaska/upp: 1.2G
* conus/upp: 3.9G

Environment and Resource
--------------------------------
1. Add ecFlow to DAFS package
2. Triggered by HRRR model data availability
3. CONUS and Alaska use the same job by different domain variable "$dom"
4. Both CONUS and Alaska UPP run takes 48 CPUs, Alaska runtime is 1 minute, CONUS runtime is 2 minutes.
5. Package size is 113MB
6. DATA working folder is 8.6GB/forecast, 155GB all forecasts for Alaska; 16GB/forecast, 278GB all forecasts for CONUS

Pre-implementation Testing Requirements
---------------------------------------
* Which production jobs should be tested as part of this implementation?
  * The entire DAFS v1.0.0 package needs to be installed and tested on WCOSS-2
* Does this change require a 30-day evaluation?
  * Yes


Products
---------------
* Directory
  * dafs/v1.0/hrrr.YYYYMMDD/CC
  * Inside DAFSv1, there is only one job running on two domains, conus and alaska
    1. At 3-hourly cycles,
       * |-- alaska/upp
       * |-- conus/upp
       * |-- conus/upp/wmo
    2. At hourly cycles,
       * |-- conus/upp
       * |-- conus/upp/wmo
* Forecast hours: f001-f018
* Cycles: conus, hourly cycle; alaska, 3-hourly cycle
* File contents
  1. Icing with three fields:
  *   Icing Probability
  *   Icing Severity
  *   Supercooled Large Droplets
  2. Turbulence with 4 fields:
  *   Clear Air Turbulence (CAT)
  *   Mountain Wave Turbulence (MWT)
  *   Convectively Induced Turbulence (CIT)
  *   Max (CAT, MWT, CIT)
  * alaska/upp/dafs.tCCz.ifi.3km.ak.fHHH.grib2 
    - 3km icing, 60 levels, every 500ft from FL005 to FL300
  * conus/upp/dafs.tCCz.gtg.3km.conus.fHHH.grib2 
    - 3km turbulence, 51 levels, one near surface (FL001) then every 1000ft from FL010 to FL500
  * conus/upp/dafs.tCCz.ifi.3km.conus.fHHH.grib2
    - 3km icing, 60 levels, every 500ft from FL005 to FL300
  * conus/upp/dafs.tCCz.gtg.13km.conus.fHHH.grib2
    - 13km turbulence, 51 levels, one near surface (FL001) then every 1000ft from FL010 to FL500
  * conus/upp/dafs.tCCz.ifi.13km.conus.fHHH.grib2
    - 13km icing, 60 levels, every 500ft from FL005 to FL300

Dissemination Information
-------------------------
* dbn_alert subtype
  | product                                               | subtype
  | ----------------------------------------------------- | ---------------------
  | dafs.tCCz.ifi.3km.ak.fHHH.grib2                       | DAFS_IFI_3km_AK_GB2
  | dafs.tCCz.ifi.3km.conus.fHHH.grib2                    | DAFS_IFI_3km_CONUS_GB2
  | dafs.tCCz.gtg.3km.conus.fHHH.grib2                    | DAFS_GTG_3km_CONUS_GB2
  | dafs.tCCz.ifi.13km.conus.fHHH.grib2                   | DAFS_IFI_13km_CONUS_GB2
  | dafs.tCCz.gtg.13km.conus.fHHH.grib2                   | DAFS_GTG_13km_CONUS_GB2
  | conus/upp/wmo/grib2.dafs.tCCz.ifi.icp.13km.conus.fHHH | hrrr
  | conus/upp/wmo/grib2.dafs.tCCz.ifi.sev.13km.conus.fHHH | hrrr
  | conus/upp/wmo/grib2.dafs.tCCz.ifi.sld.13km.conus.fHHH | hrrr


* Where should this output be sent?
  * All data is sent to AWC
  * dafs.tCCz.ifi.3km.ak.fHHH.grib2 is sent to AAWU
  * 13km products (dafs.tCCz.ifi.13km.conus.fHHH.grib2 and dafs.tCCz.gtg.13km.conus.fHHH.grib2) are sent to FAA
* Who are the users?
  * AWC, FAA, Alaska Aviation Weather Unit (AAWU)
* Which output files should be transferred from PROD WCOSS to DEV WCOSS?
  * All DAFS files should be transferred


HPSS Archive
------------
* All non-wmo files


Job Dependencies and flow diagram
---------------------------------
* Job dependencies refers to this document: https://docs.google.com/spreadsheets/d/1x0A16CzTWXQcrkBo0FxdXIt3pYstdT50Xj9HRjEq-bw
* Flow diagram refer to page 7 in this document: https://docs.google.com/presentation/d/1S1azSuRHzWaZCEDs3iOR7XAkasla1lFaesM82IAwrOQ/edit?slide=id.g377f6a1f3b0_0_0&pli=1#slide=id.g377f6a1f3b0_0_0

Documentation
-------------
* DAFS.V1 Implementation Kick-off Meeting Slides https://docs.google.com/presentation/d/1S1azSuRHzWaZCEDs3iOR7XAkasla1lFaesM82IAwrOQ
* DAFS.V1 Science Brief Meeting Slides https://docs.google.com/presentation/d/18SNAZFqIKo7dy8WLWt5S7b_Y5z1IvLeHM2OPMJnrxyw

Prepared By
-----------
* yali.mao@noaa.gov
* hsin-mu.lin@noaa.gov
