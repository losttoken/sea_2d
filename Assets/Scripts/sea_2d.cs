using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class sea_2d : MonoBehaviour
{
	float i=0.0f;

    float j=0.0f;
	
    int dir=1;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
    	if (i>1.0f){
            i=0.0f;
    	}
        else if (i<0.0f){
           
        }
           
    	i+=0.000006f;

        GetComponent<Renderer>().material.SetFloat("u_offset", i);


        if (j>33.3333333f){
            dir=-1;
        }
        else if (j<0.0f){
           dir=1;
        }
           
        j+=dir*0.001f;

        GetComponent<Renderer>().material.SetFloat("u_small_offset", j);
    }
}
