import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services as S

// The session lock. One for the session, at the shell root: WlSessionLock makes a surface per
// screen itself, and two of them would be two lock clients fighting over one session.
//
// Everything about whether to lock and when to stop lives in LockService.qml; this only connects
// it to the compositor.
Scope {
    // Assigned rather than bound: WlSessionLock sets `locked` back to false itself when the
    // compositor refuses or drops the lock, and that write would silently break a binding --
    // after which no later lock would ever reach the compositor.
    Connections {
        target: S.Lock
        function onLockedChanged() {
            lock.locked = S.Lock.locked;
        }
    }

    WlSessionLock {
        id: lock
        Component.onCompleted: lock.locked = S.Lock.locked

        onSecureChanged: S.Lock.secure = lock.secure
        onLockedChanged: {
            if (lock.locked) return;
            S.Lock.secure = false;
            // Dropped without this shell asking: the compositor refused the lock (another locker
            // holds it) or took it back. Nothing was unlocked by us, so say so and stop claiming
            // to be locked, or the next lock would look like a no-op.
            if (S.Lock.locked) S.Lock.compositorReleased();
        }

        LockSurface {}
    }
}
