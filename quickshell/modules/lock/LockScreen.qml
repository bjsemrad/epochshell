import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services as S

Scope {
    // Assigned, not bound: WlSessionLock writes `locked` back to false itself when the compositor
    // refuses or drops the lock, which would break a binding.
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
            // Dropped by the compositor, not by us: clear our state or the next lock looks like a
            // no-op.
            if (S.Lock.locked) S.Lock.compositorReleased();
        }

        LockSurface {}
    }
}
