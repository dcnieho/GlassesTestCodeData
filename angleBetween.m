function ang = angleBetween(v1,v2)
c = cross(v1,v2,2);
c = hypot(hypot(c(:,1),c(:,2)),c(:,3));
ang = (180 / pi) * atan2( c, dot(v1,v2,2) );
