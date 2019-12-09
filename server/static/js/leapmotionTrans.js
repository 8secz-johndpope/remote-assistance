class LeapmotionTrans
{
    constructor(options) 
    {
        options = options || {};
        this.alpha = 0; 
        this.beta = 0;
        this.gamma = 0;

        this.theta = 0;

        this.d = 300;

        this.d_init = options.d_init || 300;

        this.R_w_b = new THREE.Matrix4();         
        this.R_w_c = new THREE.Matrix4();
        this.t_w_c = new THREE.Vector3();        
        this.R_w_l0 = new THREE.Matrix4();  
        this.t_l_l0 = new THREE.Vector3();  
        this.T_l_c = new THREE.Matrix4(); 

        this.t_l_l0_init = new THREE.Vector3(0,200,80);
        this.t_l_l0.copy(this.t_l_l0_init);
    
    }

    ////////////////////////////////////////////////////////////
    //// public functions
    rotateCameraBody(alpha, beta, gamma)
    {
        this.alpha = alpha;
        this.beta = beta;
        this.gamma = gamma;

        this.update_R_w_b();
        this.update_R_w_c(); 
        this.update_t_w_c();       
        this.update_T_l_c();
    }

    moveLeapmotionSpace(dx, dy, dz)
    {
        this.t_l_l0.x += dx;
        this.t_l_l0.y += dy;
        this.t_l_l0.z += dz;
        
        this.update_T_l_c();       
    }

    moveLeapmotionSpaceByClick(client_x, client_y, projectionMatrix, ib_y_offset)
    {
        // screen coord. to NDC (Normalized Device Coordinates) i.e. [-1~1]
        var xn = client_x / window.innerWidth * 2 - 1.0;
        var yn = client_y / window.innerHeight * 2 - 1.0;
        
        // camera coord. space
        var T_c_l = new THREE.Matrix4().getInverse(this.T_l_c, true);
        var z = T_c_l.elements[14];        
        var x = xn / projectionMatrix.elements[0] * z;
        var y = yn / projectionMatrix.elements[5] * z - ib_y_offset;

        // translation
        var delta_c = new THREE.Vector3(x-T_c_l.elements[12],
                                        y-T_c_l.elements[13],
                                        0);
        var delta_l = new THREE.Vector3();
        delta_l.x = this.T_l_c.elements[0]*delta_c.x + this.T_l_c.elements[4]*delta_c.y + this.T_l_c.elements[8]*delta_c.z;
        delta_l.y = this.T_l_c.elements[1]*delta_c.x + this.T_l_c.elements[5]*delta_c.y + this.T_l_c.elements[9]*delta_c.z;
        delta_l.z = this.T_l_c.elements[2]*delta_c.x + this.T_l_c.elements[6]*delta_c.y + this.T_l_c.elements[10]*delta_c.z;

        this.t_l_l0.x -= delta_l.x;
        this.t_l_l0.y -= delta_l.y;
        this.t_l_l0.z -= delta_l.z;

        this.update_T_l_c();                
    }

    alignLeapmotionSpaceToGround()
    {        
        var y_l = new THREE.Vector3(0,0,1);
        var z_b = new THREE.Vector3(
                    this.R_w_c.elements[8], 
                    this.R_w_c.elements[9], 
                    this.R_w_c.elements[10]);
        var x_l = new THREE.Vector3().copy(y_l).cross(z_b).normalize();    
        var z_l = new THREE.Vector3().copy(x_l).cross(y_l).normalize();

        this.R_w_l0.set(x_l.x, y_l.x, z_l.x, 0,
                        x_l.y, y_l.y, z_l.y, 0,
                        x_l.z, y_l.z, z_l.z, 0, 
                        0, 0, 0, 1); 

        this.update_T_l_c();
    }
    
    alignLeapmotionSpaceToCamera()
    {  
        this.R_w_l0.copy(this.R_w_c)

        this.update_T_l_c();
    }


    rotateLeapmotionSpace(dtheta) // angle in degree
    {
        var cos_t = Math.cos(dtheta/180.0*Math.PI);
        var sin_t = Math.sin(dtheta/180.0*Math.PI);
        var R_old_new = new THREE.Matrix4().set(
            cos_t, 0, -sin_t, 0,
            0, 1, 0, 0, 
            sin_t, 0, cos_t, 0,
            0, 0, 0, 1
        );
        
        this.R_w_l0.multiply(R_old_new);
        this.update_T_l_c();
    }

    zoominoutCamera(delta)
    {
        this.d += delta;
        this.update_t_w_c();
        this.update_T_l_c();
    }

    setCameraDistance(d)
    {
        this.d = d;
        this.update_t_w_c();
        this.update_T_l_c();
    }

    getCameraPose()
    {
        var position = new THREE.Vector3();
        var quaternion = new THREE.Quaternion();
        var scale = new THREE.Vector3();
        this.T_l_c.decompose(position, quaternion, scale);

        return [position, quaternion];
    }

    reset()
    {
        this.alignLeapmotionSpaceToGround();
        this.t_l_l0.copy(this.t_l_l0_init);
        this.d = this.d_init;
        this.update_t_w_c();
        this.update_T_l_c();
        
    }
    

    ////////////////////////////////////////////////////////////
    //// private functions
    update_R_w_b()
    {
        // camera body must be in landscape left orientation    
        var cos_a = Math.cos(this.alpha/180.0*Math.PI);
        var sin_a = Math.sin(this.alpha/180.0*Math.PI);
        var cos_b = Math.cos(this.beta/180.0*Math.PI);
        var sin_b = Math.sin(this.beta/180.0*Math.PI);
        var cos_g = Math.cos(this.gamma/180.0*Math.PI);
        var sin_g = Math.sin(this.gamma/180.0*Math.PI);    
                
        var Rz = new THREE.Matrix4().set(
                    cos_a, -sin_a, 0, 0, 
                    sin_a, cos_a, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1);
        var Rx = new THREE.Matrix4().set(
                    1, 0, 0, 0, 
                    0, cos_b, -sin_b, 0, 
                    0, sin_b, cos_b, 0, 
                    0, 0, 0, 1);
        var Ry = new THREE.Matrix4().set(
                    cos_g, 0, sin_g, 0, 
                    0, 1, 0, 0,
                    -sin_g, 0, cos_g, 0, 
                    0, 0, 0, 1);
        
        var R_w_b = new THREE.Matrix4().multiplyMatrices(Rz, Rx);
        R_w_b.multiply(Ry);

        this.R_w_b.copy(R_w_b); 
    }

    update_R_w_c()
    {
        var x_b = new THREE.Vector3();
        var y_b = new THREE.Vector3();
        var z_b = new THREE.Vector3();
        this.R_w_b.extractBasis(x_b, y_b, z_b);
       
        var z_c = new THREE.Vector3().copy(z_b);
        var x_c = new THREE.Vector3();
        var y_c = new THREE.Vector3();

        // find closet one to z=(0,0,1) between x_b and y_b    
        if( Math.abs(x_b.z) > Math.abs(y_b.z) )
        {
            y_c.copy(x_b);
            if(x_b.z < 0)
            {
                y_c.x *= -1;
                y_c.y *= -1;
                y_c.z *= -1;
            }
        }
        else
        {
            y_c.copy(y_b);
            if(y_b.z < 0)
            {
                y_c.x *= -1;
                y_c.y *= -1;
                y_c.z *= -1;
            }
        }

        x_c.copy(z_b).cross(y_c).normalize();

        this.R_w_c.set(
            x_c.x, y_c.x, z_c.x, 0,
            x_c.y, y_c.y, z_c.y, 0,
            x_c.z, y_c.z, z_c.z, 0,
            0, 0, 0, 1
        );
    }

    update_t_w_c()
    {
        this.t_w_c.x = this.R_w_c.elements[8] * this.d;
        this.t_w_c.y = this.R_w_c.elements[9] * this.d;
        this.t_w_c.z = this.R_w_c.elements[10] * this.d;
    }
   
    update_T_l_c()
    {
        var T_l0_w = new THREE.Matrix4().copy(this.R_w_l0).transpose();

        var T_w_c = new THREE.Matrix4().set(
            this.R_w_c.elements[0], this.R_w_c.elements[4], this.R_w_c.elements[8], this.t_w_c.x, 
            this.R_w_c.elements[1], this.R_w_c.elements[5], this.R_w_c.elements[9], this.t_w_c.y, 
            this.R_w_c.elements[2], this.R_w_c.elements[6], this.R_w_c.elements[10], this.t_w_c.z, 
            0, 0, 0, 1
        );

        var T_l_l0 = new THREE.Matrix4().setPosition(this.t_l_l0);
        
        var T_l0_c = new THREE.Matrix4().multiplyMatrices(T_l0_w, T_w_c);
        this.T_l_c.multiplyMatrices(T_l_l0, T_l0_c);
    }    
}