# -*- coding: utf-8 -*-

'''
 Freeciv - Copyright (C) 2009-2014 - Andreas Røsdal   andrearo@pvv.ntnu.no
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
'''


import sys
from time import gmtime, strftime
import os
import platform
import time
from tornado import version as tornado_version
import gc

_proc_status = '/proc/%d/status' % os.getpid()

_scale = {'kB': 1024.0, 'mB': 1024.0 * 1024.0,
          'KB': 1024.0, 'MB': 1024.0 * 1024.0}

startTime = time.time()


def get_debug_info(civcoms):
    code = "<html><head><meta http-equiv=\"refresh\" content=\"20\">" \
       + "<link href='/css/bootstrap.min.css' rel='stylesheet'></head>" \
       + "<body><div class='container'>" \
       + "<h2>Freeciv WebSocket Proxy Status</h2>" \
       + "<font color=\"green\">Process status: OK</font><br>"

    code += "<b>Process Uptime: " + \
        str(int(time.time() - startTime)) + " s.</b><br>"

    code += ("Python version: %s %s (%s)<br>" % (
        platform.python_implementation(),
        platform.python_version(),
        platform.python_build()[0],
    ))

    cpu = ' '.join(platform.processor().split())
    code += ("Platform: %s %s on '%s' <br>" % (
        platform.machine(),
        platform.system(),
        cpu))

    code += ("Tornado version %s <br>" % (tornado_version))

    try:
        f = open("/proc/loadavg")
        contents = f.read()
        code += "Load average: " + contents
        f.close()
    except:
        print("Cannot open uptime file: /proc/uptime")

    try:
        code += "<h3>Memory usage:</h3>"
        code += "Memory: " + str(memory() / 1048576) + " MB <br>"
        code += "Resident: " + str(resident() / 1048576) + " MB <br>"
        code += "Stacksize: " + str(stacksize() / 1048576) + " MB <br>"
        try:
          code += "Garabage collection stats: " + str(gc.get_stats()) + " <br>"
          code += "Garabage list: " + str(gc.garbage) + " <br>"
        except AttributeError:
          pass

        code += ("<h3>Logged in users  (count %i) :</h3>" % len(civcoms))
        for key in list(civcoms.keys()):
            code += (
                "username: <b>%s</b> <br>IP:%s <br>Civserver: (%d)<br>Connect time: %d<br><br>" %
                (civcoms[key].username,
                 civcoms[key].civwebserver.ip,
                    civcoms[key].civserverport,
                    time.time() -
                    civcoms[key].connect_time))

    except:
        print(("Unexpected error:" + str(sys.exc_info()[0])))
        raise

    code += "</div></body></html>"

    return code


def _VmB(VmKey):
    '''Private.
    '''
    global _proc_status, _scale
     # get pseudo file  /proc/<pid>/status
    try:
        t = open(_proc_status)
        v = t.read()
        t.close()
    except:
        return 0.0  # non-Linux?
     # get VmKey line e.g. 'VmRSS:  9999  kB\n ...'
    i = v.index(VmKey)
    v = v[i:].split(None, 3)  # whitespace
    if len(v) < 3:
        return 0.0  # invalid format?
     # convert Vm value to bytes
    return float(v[1]) * _scale[v[2]]


def memory(since=0.0):
    '''Return memory usage in bytes.
    '''
    return _VmB('VmSize:') - since


def resident(since=0.0):
    '''Return resident memory usage in bytes.
    '''
    return _VmB('VmRSS:') - since


def stacksize(since=0.0):
    '''Return stack size in bytes.
    '''
    return _VmB('VmStk:') - since
